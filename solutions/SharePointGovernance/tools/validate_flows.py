"""Static checks for the governance flow definitions.

Catches the mistakes Power Automate only reports at import or run time:
duplicate action names, dangling runAfter / body() / outputs() references,
undeclared parameters or variables, and SharePoint columns that the flows
read or write but sharepoint/list-schema.json does not define.

Usage: python solutions/SharePointGovernance/tools/validate_flows.py
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FLOWS = sorted((ROOT / "powerautomate" / "flows").glob("*.json"))
SCHEMA = json.loads((ROOT / "sharepoint" / "list-schema.json").read_text())

# Columns every SharePoint list has without being declared.
BUILTIN = {"ID", "Title", "{Link}", "Created", "Modified", "Author", "Editor"}

ACTION_REF = re.compile(r"\b(?:body|outputs|actions|items)\('([^']+)'\)")
PARAM_REF = re.compile(r"\bparameters\('([^']+)'\)")
VAR_REF = re.compile(r"\bvariables\('([^']+)'\)")
TRIGGER_FIELD = re.compile(r"triggerBody\(\)\?\['([^']+)'\]")
ITEM_FIELD = re.compile(r"\bitems\('([^']+)'\)\?\['([^']+)'\]")


def list_columns():
    cols = {}
    for lst in SCHEMA["lists"]:
        cols[lst["listTitle"]] = BUILTIN | {f["internalName"] for f in lst["fields"]}
    return cols


def choice_values():
    return {(lst["listTitle"], f["internalName"]): set(f["choices"])
            for lst in SCHEMA["lists"] for f in lst["fields"] if f["type"] == "Choice"}


CHOICES = choice_values()
LITERAL = re.compile(r"'([^']*)'")


def walk_actions(actions, scope, found):
    """Yield (name, action, sibling_names) for every action at any depth."""
    for name, action in actions.items():
        found.append((name, action, set(actions), scope))
        for key in ("actions",):
            if key in action:
                walk_actions(action[key], name, found)
        if "else" in action:
            walk_actions(action["else"].get("actions", {}), name, found)
        for case in action.get("cases", {}).values():
            walk_actions(case.get("actions", {}), name, found)
        if "default" in action:
            walk_actions(action["default"].get("actions", {}), name, found)
    return found


def strings(node):
    if isinstance(node, str):
        yield node
    elif isinstance(node, dict):
        for k, v in node.items():
            yield k
            yield from strings(v)
    elif isinstance(node, list):
        for v in node:
            yield from strings(v)


def sp_table(action):
    inputs = action.get("inputs")
    if not isinstance(inputs, dict):
        return None, None
    params = inputs.get("parameters", {})
    host = inputs.get("host", {})
    if host.get("connectionName") == "shared_sharepointonline" and "table" in params:
        return params["table"], params
    return None, None


def check(path, columns):
    errors = []
    doc = json.loads(path.read_text())
    for key in ("displayName", "description", "triggers", "actions", "parameters"):
        if key not in doc:
            errors.append(f"missing top-level '{key}'")

    found = walk_actions(doc["actions"], None, [])
    names = [n for n, *_ in found]
    dupes = {n for n in names if names.count(n) > 1}
    for d in sorted(dupes):
        errors.append(f"duplicate action name '{d}'")
    by_name = {n: a for n, a, *_ in found}

    variables = {v["name"] for a in by_name.values() if a.get("type") == "InitializeVariable"
                 for v in a["inputs"]["variables"]}
    loops = {n for n, a in by_name.items() if a.get("type") == "Foreach"}

    for name, action, siblings, _ in found:
        for dep in action.get("runAfter", {}):
            if dep not in siblings:
                errors.append(f"{name}: runAfter '{dep}' is not a sibling action")

    text = list(strings(doc["actions"])) + list(strings(doc["triggers"]))
    for s in text:
        for ref in ACTION_REF.findall(s):
            if ref not in by_name:
                errors.append(f"reference to unknown action '{ref}'")
        for ref in PARAM_REF.findall(s):
            if ref not in doc["parameters"]:
                errors.append(f"undeclared parameter '{ref}'")
        for ref in VAR_REF.findall(s):
            if ref not in variables:
                errors.append(f"uninitialised variable '{ref}'")
        for loop, _ in ITEM_FIELD.findall(s):
            if loop not in loops:
                errors.append(f"items('{loop}') used but '{loop}' is not a Foreach")

    # SharePoint columns
    trigger = next(iter(doc["triggers"].values()))
    trig_table, _ = sp_table(trigger)
    if trig_table:
        if trig_table not in columns:
            errors.append(f"trigger list '{trig_table}' not in schema")
        else:
            for s in text:
                for col in TRIGGER_FIELD.findall(s):
                    if col not in columns[trig_table]:
                        errors.append(f"trigger column '{trig_table}.{col}' not in schema")

    loop_tables = {}
    for name, action, *_ in found:
        table, params = sp_table(action)
        if not table:
            continue
        if table not in columns:
            errors.append(f"{name}: list '{table}' not in schema")
            continue
        if action["inputs"]["host"]["operationId"] == "GetItems":
            loop_tables[name] = table
        for key, value in params.items():
            if not key.startswith("item/"):
                continue
            col = key.split("/")[1]
            if col not in columns[table]:
                errors.append(f"{name}: column '{table}.{col}' not in schema")
                continue
            allowed = CHOICES.get((table, col))
            if allowed is None or not isinstance(value, str):
                continue
            # A literal value must be a choice; for if(...) expressions check each quoted outcome.
            if not value.startswith("@"):
                candidates = [value]
            elif value.startswith("@if("):
                candidates = LITERAL.findall(value)[-2:]
            else:
                candidates = []
            for v in candidates:
                if v not in allowed:
                    errors.append(f"{name}: '{v}' is not a choice of '{table}.{col}'")
    # items('Loop')?['Col'] where the loop iterates a GetItems result
    for loop in loops:
        source = ACTION_REF.findall(by_name[loop]["foreach"])
        table = loop_tables.get(source[0]) if source else None
        if not table:
            continue
        for s in text:
            for ref_loop, col in ITEM_FIELD.findall(s):
                if ref_loop == loop and col not in columns[table]:
                    errors.append(f"loop column '{table}.{col}' not in schema")
    # GetItem results read via body('Get_x')?['Col']
    for name, action, *_ in found:
        table, _ = sp_table(action)
        if table and action["inputs"]["host"]["operationId"] == "GetItem" and table in columns:
            for s in text:
                for col in re.findall(rf"body\('{re.escape(name)}'\)\?\['([^']+)'\]", s):
                    if col not in columns[table]:
                        errors.append(f"column '{table}.{col}' (via {name}) not in schema")
    return sorted(set(errors))


def main():
    columns = list_columns()
    failed = False
    for path in FLOWS:
        errors = check(path, columns)
        status = "ok" if not errors else f"{len(errors)} problem(s)"
        print(f"{path.name}: {status}")
        for e in errors:
            print(f"  - {e}")
        failed |= bool(errors)
    if not FLOWS:
        print("no flows found")
        failed = True
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()

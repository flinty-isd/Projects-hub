"""Package the governance flows as an unmanaged Power Platform solution (.zip).

The output imports through Power Automate > Solutions > Import solution. It
contains:

  * one cloud flow per file in powerautomate/flows/ (created switched off)
  * one connection reference per connector, which the import wizard asks
    you to bind to a connection
  * one environment variable per flow parameter (the governance site URL,
    the role mailboxes, the Automation account), which the import wizard asks
    you to fill in

Flow and component IDs are derived from the names, so rebuilding produces
the same IDs and a re-import upgrades the existing flows instead of adding
copies. Bump "version" in solution-config.json for each release.

Usage:
  python solutions/SharePointGovernance/tools/build_solution.py [--out DIR] [--root SOLUTION_DIR]
"""
import argparse
import copy
import json
import re
import sys
import uuid
import zipfile
from pathlib import Path
from xml.sax.saxutils import escape, quoteattr

def _root():
    """--root SOLUTION_DIR packages another solution folder laid out the same way."""
    if "--root" in sys.argv:
        return Path(sys.argv[sys.argv.index("--root") + 1]).resolve()
    return Path(__file__).resolve().parent.parent


ROOT = _root()
FLOWS = sorted((ROOT / "powerautomate" / "flows").glob("*.json"))
CONFIG = json.loads((ROOT / "solution-config.json").read_text())

# Fixed namespace so IDs are stable across builds.
NAMESPACE = uuid.UUID("6f1c4a52-3b1e-4f43-9a51-2d0c8e4b7a10")

ENV_TYPES = {"String": "100000000", "Int": "100000001", "Bool": "100000002"}
PARAM_REF = re.compile(r"parameters\('([^']+)'\)")


def stable_id(*parts):
    return str(uuid.uuid5(NAMESPACE, "/".join(parts)))


def schema_name(param):
    return f"{CONFIG['publisher']['prefix']}_{param}"


def env_param_name(param):
    """Power Automate's own naming for a parameter backed by an environment variable."""
    return f"{CONFIG['environmentVariables'][param]['displayName']} ({schema_name(param)})"


def conn_ref_name(api):
    # connectionReferenceTag keeps two solutions in one environment on separate connections.
    return f"{CONFIG['publisher']['prefix']}_{CONFIG.get('connectionReferenceTag', '')}{api.replace('_', '')}"


def rewrite_params(node, mapping):
    """Point every parameters('X') reference at the environment-variable parameter."""
    if isinstance(node, str):
        return PARAM_REF.sub(lambda m: f"parameters('{mapping.get(m.group(1), m.group(1))}')", node)
    if isinstance(node, dict):
        return {rewrite_params(k, mapping): rewrite_params(v, mapping) for k, v in node.items()}
    if isinstance(node, list):
        return [rewrite_params(v, mapping) for v in node]
    return node


def build_flow(src):
    flow = json.loads(src.read_text())
    params = {k: v for k, v in flow["parameters"].items() if not k.startswith("$")}
    unknown = set(params) - set(CONFIG["environmentVariables"])
    if unknown:
        sys.exit(f"{src.name}: parameters without an environment variable in solution-config.json: {sorted(unknown)}")
    mapping = {p: env_param_name(p) for p in params}

    definition = {
        "$schema": flow["$schema"],
        "contentVersion": flow["contentVersion"],
        "parameters": {
            "$connections": {"defaultValue": {}, "type": "Object"},
            "$authentication": {"defaultValue": {}, "type": "SecureObject"},
        },
        "triggers": rewrite_params(copy.deepcopy(flow["triggers"]), mapping),
        "actions": rewrite_params(copy.deepcopy(flow["actions"]), mapping),
    }
    for p, spec in params.items():
        definition["parameters"][mapping[p]] = {
            "defaultValue": spec["defaultValue"],
            "type": spec["type"],
            "metadata": {"schemaName": schema_name(p)},
        }

    conn_refs = {}
    for api in flow["connectionReferences"]:
        if api not in CONFIG["connectionReferences"]:
            sys.exit(f"{src.name}: connector {api} has no connection reference in solution-config.json")
        conn_refs[api] = {
            "runtimeSource": "embedded",
            "connection": {"connectionReferenceLogicalName": conn_ref_name(api)},
            "api": {"name": api},
        }
    body = {"properties": {"connectionReferences": conn_refs, "definition": definition},
            "schemaVersion": "1.0.0.0"}

    workflow_id = stable_id("workflow", src.stem)
    safe = re.sub(r"[^A-Za-z0-9]", "", flow["displayName"])
    return {
        "id": workflow_id,
        "name": flow["displayName"],
        "description": flow["description"],
        "file": f"Workflows/{safe}-{workflow_id.upper()}.json",
        "json": json.dumps(body, indent=2, ensure_ascii=False),
        "params": params,
        "apis": list(flow["connectionReferences"]),
    }


def workflow_xml(f):
    return f"""    <Workflow WorkflowId="{{{f['id']}}}" Name={quoteattr(f['name'])} Description={quoteattr(f['description'])}>
      <JsonFileName>/{f['file']}</JsonFileName>
      <Type>1</Type>
      <Subprocess>0</Subprocess>
      <Category>5</Category>
      <Mode>0</Mode>
      <Scope>4</Scope>
      <OnDemand>0</OnDemand>
      <TriggerOnCreate>0</TriggerOnCreate>
      <TriggerOnDelete>0</TriggerOnDelete>
      <AsyncAutodelete>0</AsyncAutodelete>
      <SyncWorkflowLogOnFailure>0</SyncWorkflowLogOnFailure>
      <StateCode>0</StateCode>
      <StatusCode>1</StatusCode>
      <RunAs>1</RunAs>
      <IsTransacted>1</IsTransacted>
      <IntroducedVersion>1.0.0.0</IntroducedVersion>
      <IsCustomizable>1</IsCustomizable>
      <BusinessProcessType>0</BusinessProcessType>
      <IsCustomProcessingStepAllowedForOtherPublishers>1</IsCustomProcessingStepAllowedForOtherPublishers>
      <PrimaryEntity>none</PrimaryEntity>
      <LocalizedNames>
        <LocalizedName languagecode="1033" description={quoteattr(f['name'])} />
      </LocalizedNames>
    </Workflow>"""


def connection_reference_xml(api):
    return f"""    <connectionreference connectionreferencelogicalname="{conn_ref_name(api)}">
      <connectionreferencedisplayname>{escape(CONFIG['connectionReferences'][api])}</connectionreferencedisplayname>
      <connectorid>/providers/Microsoft.PowerApps/apis/{api}</connectorid>
      <iscustomizable>1</iscustomizable>
      <statecode>0</statecode>
      <statuscode>1</statuscode>
    </connectionreference>"""


def env_var_xml(param, ptype):
    spec = CONFIG["environmentVariables"][param]
    value = spec.get("default")
    if isinstance(value, bool):
        value = "yes" if value else "no"  # how Dataverse stores a Boolean environment variable
    default = f"\n  <defaultvalue>{escape(str(value))}</defaultvalue>" if "default" in spec else ""
    # Never mandatory at import: the import screen can block or show variables without their
    # titles. Values are set afterwards under Solutions > Environment variables, where the
    # display names always show. Variables with no default say so in their description.
    description = spec["description"] if "default" in spec else f"Set after import. {spec['description']}"
    return f"""<environmentvariabledefinition schemaname="{schema_name(param)}">{default}
  <description default={quoteattr(description)}>
    <label description={quoteattr(description)} languagecode="1033" />
  </description>
  <displayname default={quoteattr(spec['displayName'])}>
    <label description={quoteattr(spec['displayName'])} languagecode="1033" />
  </displayname>
  <introducedversion>1.0.0.0</introducedversion>
  <iscustomizable>1</iscustomizable>
  <isrequired>0</isrequired>
  <secretstore>0</secretstore>
  <type>{ENV_TYPES[ptype]}</type>
</environmentvariabledefinition>
"""


def solution_xml(flows, env_vars):
    pub = CONFIG["publisher"]
    roots = [f'      <RootComponent type="29" id="{{{f["id"]}}}" behavior="0" />' for f in flows]
    roots += [f'      <RootComponent type="380" schemaName="{schema_name(p)}" behavior="0" />' for p in env_vars]
    address = "\n".join(f"""        <Address>
          <AddressNumber>{n}</AddressNumber>
          <AddressTypeCode>1</AddressTypeCode>
          <ShippingMethodCode>1</ShippingMethodCode>
        </Address>""" for n in (1, 2))
    return f"""<?xml version="1.0" encoding="utf-8"?>
<ImportExportXml version="9.2.24074.198" SolutionPackageVersion="9.2" languagecode="1033" generatedBy="CrmLive" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <SolutionManifest>
    <UniqueName>{CONFIG['uniqueName']}</UniqueName>
    <LocalizedNames>
      <LocalizedName description={quoteattr(CONFIG['displayName'])} languagecode="1033" />
    </LocalizedNames>
    <Descriptions>
      <Description description={quoteattr(CONFIG['description'])} languagecode="1033" />
    </Descriptions>
    <Version>{CONFIG['version']}</Version>
    <Managed>0</Managed>
    <Publisher>
      <UniqueName>{pub['uniqueName']}</UniqueName>
      <LocalizedNames>
        <LocalizedName description={quoteattr(pub['displayName'])} languagecode="1033" />
      </LocalizedNames>
      <Descriptions />
      <EMailAddress xsi:nil="true"></EMailAddress>
      <SupportingWebsiteUrl xsi:nil="true"></SupportingWebsiteUrl>
      <CustomizationPrefix>{pub['prefix']}</CustomizationPrefix>
      <CustomizationOptionValuePrefix>{pub['optionValuePrefix']}</CustomizationOptionValuePrefix>
      <Addresses>
{address}
      </Addresses>
    </Publisher>
    <RootComponents>
{chr(10).join(roots)}
    </RootComponents>
    <MissingDependencies />
  </SolutionManifest>
</ImportExportXml>
"""


def customizations_xml(flows, apis):
    return f"""<?xml version="1.0" encoding="utf-8"?>
<ImportExportXml xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <Entities />
  <Roles />
  <Workflows>
{chr(10).join(workflow_xml(f) for f in flows)}
  </Workflows>
  <FieldSecurityProfiles />
  <Templates />
  <EntityMaps />
  <EntityRelationships />
  <OrganizationSettings />
  <optionsets />
  <CustomControls />
  <EntityDataProviders />
  <connectionreferences>
{chr(10).join(connection_reference_xml(a) for a in apis)}
  </connectionreferences>
  <Languages>
    <Language>1033</Language>
  </Languages>
</ImportExportXml>
"""


CONTENT_TYPES = """<?xml version="1.0" encoding="utf-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="xml" ContentType="application/octet-stream" /><Default Extension="json" ContentType="application/octet-stream" /></Types>"""


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default=str(ROOT / "dist"), help="output directory (default: dist/)")
    ap.add_argument("--root", help="solution folder to package (default: SharePointGovernance)")
    args = ap.parse_args()

    flows = [build_flow(p) for p in FLOWS]
    env_vars = {}
    for f in flows:
        for p, spec in f["params"].items():
            env_vars.setdefault(p, spec["type"])
    apis = sorted({a for f in flows for a in f["apis"]})

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    zip_path = out / f"{CONFIG['uniqueName']}_{CONFIG['version'].replace('.', '_')}.zip"
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", CONTENT_TYPES)
        z.writestr("solution.xml", solution_xml(flows, env_vars))
        z.writestr("customizations.xml", customizations_xml(flows, apis))
        for f in flows:
            z.writestr(f["file"], f["json"])
        for p, ptype in sorted(env_vars.items()):
            z.writestr(f"environmentvariabledefinitions/{schema_name(p)}/environmentvariabledefinition.xml",
                       env_var_xml(p, ptype))
    print(f"Built {zip_path} ({len(flows)} flows, {len(apis)} connection references, "
          f"{len(env_vars)} environment variables)")


if __name__ == "__main__":
    main()

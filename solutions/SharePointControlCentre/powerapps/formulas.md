# Control Centre Attention app — Power Fx formula reference

The one thing native SharePoint genuinely can't do for this solution: merge
`SP_RAID` + `SP_Actions` + `SP_MigrationRegister` + `SP_Decisions` into a
single "Attention Required" view. This is the Power Fx to build that as a
one-screen Canvas app, embedded on the Programme Control Centre page via the
native **Power Apps web part**.

**This is the reliable half of this folder.** The formulas below are plain
Power Fx, which is stable and well-documented - copy them straight into
Power Apps Studio. `../src/` also has a best-effort attempt at the modern
Power Apps *source file* package (the `.fx.yaml` / `CanvasManifest.json`
format `pac canvas pack` produces) for importing instead of building by
hand, but that packaging format could not be verified against anything in
this environment - no Power Platform CLI, no reachable reference, nothing.
If it fails to import, or imports but looks wrong, these formulas are the
fallback: build the app by hand in Studio and paste each one in.

## Setup

1. New blank Canvas app (tablet layout).
2. **Data > Add data > SharePoint** → connect to the Control Centre site →
   add `SP_RAID`, `SP_Actions`, `SP_MigrationRegister`, `SP_Decisions`.
3. One screen, named `AttentionScreen`.

## A note on column references

SharePoint columns created as **Choice** fields (RAG, Status, Migration
Status, etc.) usually surface in Power Apps as plain text, so
`RAG = "Red"` is normally correct. Some connector versions instead expose a
Choice column as a record with a `.Value` property (`RAG.Value = "Red"`).
**Check one real row in App Checker / the formula bar first** - if a
comparison silently returns no rows, that's almost certainly why; add
`.Value` to that column everywhere it's used.

**Person** columns (`Owner`, `Business Owner`, `Migration Owner`, etc.) are
records - `Owner.DisplayName` for the name shown below, `Owner.Email` if you
need it elsewhere.

## App.OnStart — build the unified collection

```powerfx
ClearCollect(
    colAttention,
    AddColumns(
        Filter(SP_RAID, RAG = "Red", Status = "Open"),
        "Category", "Red RAID",
        "Description", Title,
        "OwnerName", Owner.DisplayName,
        "RAGValue", "Red"
    )
);
Collect(
    colAttention,
    AddColumns(
        Filter(SP_Actions, Status <> "Closed", DueDate < Today()),
        "Category", "Overdue Action",
        "Description", Title,
        "OwnerName", Owner.DisplayName,
        "RAGValue", "Red"
    )
);
Collect(
    colAttention,
    AddColumns(
        Filter(SP_MigrationRegister, 'Migration Status' = "Blocked"),
        "Category", "Blocked Site",
        "Description", Title & " - " & 'Blocker / Dependency',
        "OwnerName", 'Migration Owner'.DisplayName,
        "RAGValue", "Red"
    )
);
Collect(
    colAttention,
    AddColumns(
        Filter(SP_Decisions, Status = "Pending"),
        "Category", "Decision Required",
        "Description", Title,
        "OwnerName", Owner.DisplayName,
        "RAGValue", "Amber"
    )
);
```

`colAttention` ends up with one shape regardless of source list: `Category`,
`Description`, `OwnerName`, `RAGValue` - that's what makes one gallery able
to show all four.

## Headline labels (top of screen)

| Control | Property | Formula |
|---|---|---|
| `lblSitesComplete` | Text | `="209"` — the validated baseline (an authorised figure, not computed - see the Implementation Specification) |
| `lblRemainingSites` | Text | `=Text(CountRows(Filter(SP_MigrationRegister, 'Migration Status' <> "Complete")))` |
| `lblOverdueActions` | Text | `=Text(CountRows(Filter(SP_Actions, Status <> "Closed", DueDate < Today())))` |

## Filter dropdown (optional but cheap)

`ddRAGFilter`:
- Items: `=["All", "Red", "Amber"]`
- Default selected: `"All"`

## Gallery (`galAttention`, vertical, blank/flexible height)

- Items: `=If(ddRAGFilter.Selected.Value = "All", colAttention, Filter(colAttention, RAGValue = ddRAGFilter.Selected.Value))`

Inside the gallery template:

| Control | Property | Formula |
|---|---|---|
| `rectRAG` (a thin rectangle, left edge of each row) | Fill | `=If(ThisItem.RAGValue = "Red", RGBA(168, 0, 0, 1), RGBA(152, 111, 11, 1))` |
| `lblCategory` | Text | `=ThisItem.Category` |
| `lblDescription` | Text | `=ThisItem.Description` |
| `lblOwner` | Text | `=ThisItem.OwnerName` |

## Refresh button (`btnRefresh`)

- OnSelect: the exact same `ClearCollect` / `Collect` / `Collect` / `Collect`
  block from App.OnStart, repeated. Canvas apps don't have reusable
  functions outside components, so duplicating it here is normal, not a
  mistake.

## Embedding on the SharePoint page

Publish the app, then on the Programme Control Centre page: **Edit → add a
web part → Power Apps → paste the app's Web Link**. It replaces (or sits
alongside) the four stacked List web parts from
[`../../diagrams/page-layout.md`](../../diagrams/page-layout.md) - keep both
until people have actually used the merged version and prefer it.

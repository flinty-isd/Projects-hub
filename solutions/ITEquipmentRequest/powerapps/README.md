# IT Equipment Request — Power Apps canvas app (source)

This folder holds the **source-controlled** representation of the canvas app, in
the same `.pa.yaml` format produced by:

```sh
pac canvas pack --sources ./src --msapp ./build/ITEquipmentRequest.msapp
```

or by choosing **File → Save as → This computer → source code** in Power Apps
Studio. The `.msapp` binary is a *build artifact* — don't hand-edit it or commit
it; regenerate it from `src/` (or unpack a Studio-authored `.msapp` back into
`src/` with `pac canvas unpack` after making UI changes in Studio, then commit
the resulting `.pa.yaml`).

## Layout

```
src/
  CanvasManifest.json     # app metadata, data sources, screen order
  Screens/
    RequestForm.fx.yaml   # the single screen for this form (replaces InfoPath's one view)
```

## Screens vs. InfoPath views

The original InfoPath form had a single view, so there is one screen,
`RequestForm`. A form with multiple InfoPath views (e.g. a distinct "Manager
Approval" view) should become one screen per view, with `Navigate()` calls
replacing InfoPath's view-switching rules.

## Data source

`RequestForm` connects to the **IT Equipment Requests** SharePoint list (schema in
[`../sharepoint/list-schema.json`](../sharepoint/list-schema.json)) via the
standard SharePoint connector, added in Studio as
`Data > Add data > SharePoint > IT Equipment Requests`.

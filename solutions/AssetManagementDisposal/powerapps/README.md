# Asset Management & Disposal — Power Apps canvas app (source)

Source-controlled `.pa.yaml` in the same format produced by:

```sh
pac canvas pack --sources ./src --msapp ./build/AssetManagementDisposal.msapp
```

See [`../../ITEquipmentRequest/powerapps/README.md`](../../ITEquipmentRequest/powerapps/README.md)
for the general notes on this format (build artifact vs. source, how to
regenerate). Don't hand-edit `.msapp`.

## Screens

| Screen | Purpose | Data source |
|---|---|---|
| `AssetRegister.fx.yaml` | Browse/search the asset inventory; select an asset to request disposal | `Asset Register` SharePoint list |
| `DisposalRequestForm.fx.yaml` | Submit a disposal request for the selected asset | `Disposal Requests` SharePoint list |

Both lists are added via `Data > Add data > SharePoint`, schema in
[`../sharepoint/list-schema.json`](../sharepoint/list-schema.json).

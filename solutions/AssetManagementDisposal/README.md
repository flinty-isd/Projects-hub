# Asset Management & Disposal

Replaces the legacy InfoPath "IT Asset Disposal Form" (and the ad-hoc spreadsheet
often used alongside it to track what assets exist). Two related lists:

1. **Asset Register** — the master inventory of IT/corporate assets and their
   lifecycle status.
2. **Disposal Requests** — a request to retire/dispose of one asset, routed
   through approval, with a mandatory data-wipe certification for any asset
   that stores data before it can be marked disposed.

See [`../../docs/infopath-migration/migration-guide.md`](../../docs/infopath-migration/migration-guide.md)
for the general migration process this solution follows, and
[`../ITEquipmentRequest`](../ITEquipmentRequest) for the simpler single-list
reference example.

## Folders

| Folder | Contents |
|---|---|
| `sharepoint/` | List schemas for Asset Register and Disposal Requests |
| `powerapps/` | Canvas app source: browse/search the register, submit a disposal request |
| `powerautomate/` | Approval flow that routes disposal requests and updates the register |

## Compliance note

Disposal of any asset flagged `StoresData = Yes` (laptops, phones, servers,
drives) **must not** be marked `Disposed` in the Asset Register until
`DataWipeCertified = Yes` on its Disposal Request — enforced by the flow in
`powerautomate/flows/Submit-DisposalRequest.json`, not just by client-side
validation in the app. Adjust the certification/vendor fields to match your
organization's actual e-waste/data-destruction policy before using this in
production.

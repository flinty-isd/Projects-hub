# Migration Guide: InfoPath Form → Power Apps + Power Automate

Follow these steps for each legacy InfoPath form. Use
[`solutions/ITEquipmentRequest`](../../solutions/ITEquipmentRequest) as a reference
implementation of the pattern described below.

## 1. Inventory the InfoPath form

- Open the `.xsn` template (or the published form library) and note:
  - Every field/control and its data type (text, choice, person, date, repeating table).
  - Validation rules and conditional formatting.
  - Rules/data connections (submit to SharePoint list, send email, etc.).
  - Views (e.g. a different layout for managers vs. requesters).
- Export the InfoPath data source schema (`File > Info > Form Data > Manage Data
  Connections`, or inspect `manifest.xsf`/`sampledata.xml` inside the `.xsn`) — this
  becomes the basis for the new data schema.

## 2. Design the data store

- One SharePoint list column (or Dataverse table column) per InfoPath field.
- Repeating tables become a **child list** related by a lookup column, not multiple
  columns — see `sharepoint/list-schema.json` in the example for the shape to use.
- Keep column **internal names** stable and documented; Power Apps/Power Automate
  reference them by internal name, not display name.

## 3. Build the Power Apps canvas app

- One screen per InfoPath *view*.
- Recreate validation with control `DisplayMode`/`Error` formulas, not code-behind.
- Use `Patch()`/`SubmitForm()` against the SharePoint list from step 2.
- Store the canvas app source under `powerapps/src/` in `.pa.yaml` format (produced
  by `pac canvas pack --unpack` or the "Save as source control friendly" option in
  Power Apps Studio) so it can be code-reviewed. The `.msapp` binary is a build
  artifact, not something to hand-edit — regenerate it with:

  ```sh
  pac canvas pack --sources ./powerapps/src --msapp ./build/ITEquipmentRequest.msapp
  ```

## 4. Build the Power Automate flow(s)

- Replace InfoPath "rules" and "data connections" with a cloud flow triggered
  `When an item is created or modified` on the SharePoint list.
- Author the flow definition as JSON (Workflow Definition Language) under
  `powerautomate/flows/`, matching what `pac flow` / solution export produces, so
  changes are diffable in PRs.
- Common InfoPath behaviors and their Power Automate equivalent:
  | InfoPath | Power Automate |
  |---|---|
  | Submit data connection to SharePoint | List item already created by Power Apps `Patch`; flow reacts to it |
  | Send mail rule | `Send an email (V2)` action |
  | Workflow approval | `Start and wait for an approval` |
  | Set a field based on a condition | `Condition` control + `Update item` |

## 5. Wire up the CI/CD pipeline

- Package the canvas app + flow + list schema into a single **solution** (see
  `architecture.md#alm-pipeline`).
- The GitHub Actions workflow (`.github/workflows/power-platform-ci.yml`) packs the
  unmanaged solution source into a `.zip` and (on merge to `main`) imports it as a
  **managed** solution into the target environment using `microsoft/powerplatform-actions`.

## 6. Decommission the InfoPath form

- Once the Power Apps replacement is validated by end users:
  1. Point the SharePoint list/library's "New"/"Edit" command to the Power App
     (`Customize forms` blocked → use `Integrate > Power Apps > Customize forms`,
     or embed the canvas app via the Power Apps web part on a modern page).
  2. Disable InfoPath form submission (`Library Settings > Advanced Settings >
     Custom Send To Destination` and/or `Form Settings`).
  3. Archive the `.xsn` template and original data for audit purposes.
  4. Update the migration backlog table in `docs/infopath-migration/README.md`.

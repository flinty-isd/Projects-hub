# IT Equipment Request — Power Automate flow(s)

`flows/Submit-EquipmentRequest.json` is the flow definition in the Workflow
Definition Language JSON that `pac flow` / solution export/unpack produces, so
it can be diffed and reviewed in pull requests like any other source file.

To import it into an environment for the first time, create a flow in
[make.powerautomate.com](https://make.powerautomate.com) with matching trigger
and actions (or add it to a solution and use the CI pipeline in
[`../../.github/workflows/power-platform-ci.yml`](../../../.github/workflows/power-platform-ci.yml)),
then keep it in sync with this file going forward via `pac flow` export.

## What it replaces from InfoPath

| InfoPath behavior | Flow equivalent |
|---|---|
| "Submit" data connection writing to a SharePoint list | Not needed — Power Apps `SubmitForm()` already created the item; the flow triggers on that item |
| Rule: "send confirmation email to requester" | `Send an email (V2)` action, `Notify requester` |
| Workflow: route to manager for approval | `Start and wait for an approval` (assigned to the item's `Manager` person field) |
| Rule: "set status based on approval outcome" | `Condition` + `Update item` (sets `ApprovalStatus`/`ApproverComments`) |

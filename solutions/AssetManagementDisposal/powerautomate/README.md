# Asset Management & Disposal — Power Automate flow(s)

`flows/Submit-DisposalRequest.json` is the flow definition (Workflow
Definition Language JSON) in the format `pac flow` / solution export/unpack
produces, kept as source for review in pull requests.

## What it replaces from InfoPath

| InfoPath behavior | Flow equivalent |
|---|---|
| Submit data connection writing to a SharePoint list | Not needed — Power Apps `SubmitForm()` already created the item; the flow triggers on that item |
| Manual e-mail/paper sign-off for disposal | `Start and wait for an approval`, assigned to the asset manager |
| No enforced data-wipe check (a checkbox on the form nobody verified) | `Condition` blocking approval — see below |
| Spreadsheet update after disposal | `Update item` on `Asset Register` setting `LifecycleStatus` |

## Data-wipe compliance gate

Before routing to approval, the flow checks the linked asset's `StoresData`
field. If `StoresData = Yes` and the request's `DataWipeCertified` is not
`Yes`, the flow **does not start an approval** — it sets
`ApprovalStatus = "Blocked - Data Wipe Required"` and emails the requester,
so a data-bearing asset can never be approved for disposal without a
certificate on file. This is enforced server-side because the InfoPath/manual
process relied on a human noticing an unchecked box.

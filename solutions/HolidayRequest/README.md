# Holiday Request

Replaces the legacy InfoPath "Holiday/Annual Leave Request Form". Two related
lists:

1. **Holiday Balances** — each employee's entitlement, taken, and remaining
   days for a given year.
2. **Holiday Requests** — a request for time off, routed to the employee's
   manager for approval, with a balance check that blocks submitting more
   days than are actually remaining.

See [`../../docs/infopath-migration/migration-guide.md`](../../docs/infopath-migration/migration-guide.md)
for the general migration process, and [`../ITEquipmentRequest`](../ITEquipmentRequest) /
[`../AssetManagementDisposal`](../AssetManagementDisposal) for the other
reference examples.

## Folders

| Folder | Contents |
|---|---|
| `sharepoint/` | List schemas for Holiday Balances and Holiday Requests |
| `powerapps/` | Canvas app source: my requests + balance summary, new request form |
| `powerautomate/` | Approval flow: balance check, manager approval, balance update, calendar event |

## Business rule enforced server-side

InfoPath's version of this form let a requester submit any number of days —
the balance was just a reference number someone read, not something checked.
The flow in `powerautomate/flows/Submit-HolidayRequest.json` looks up the
employee's `Holiday Balances` record for `HolidayType = "Annual Leave"` and
refuses to route the request for approval (setting
`ApprovalStatus = "Blocked - Insufficient Balance"` instead) when
`TotalDaysRequested` exceeds `RemainingDays`. Sick/unpaid/compassionate leave
types skip the balance check, matching typical policy (adjust to your org's
actual leave policy before using this in production).

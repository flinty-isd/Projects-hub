# Holiday Request — Power Automate flow(s)

`flows/Submit-HolidayRequest.json` is the flow definition (Workflow
Definition Language JSON) in the format `pac flow` / solution export/unpack
produces, kept as source for review in pull requests.

## What it replaces from InfoPath

| InfoPath behavior | Flow equivalent |
|---|---|
| Submit data connection writing to a SharePoint list | Not needed — Power Apps already created the item; the flow triggers on that item |
| Manual e-mail sign-off from a manager | `Start and wait for an approval`, assigned to the request's `Manager` |
| Requester's self-typed "days remaining" note | `Get_holiday_balance` action + the balance-check gate below |
| Someone manually updating a spreadsheet after approval | `Update_balance_TakenDays` on `Holiday Balances` |
| Someone manually blocking out the team calendar | `Create_calendar_event` (Office 365 Outlook) on approval |

## Balance-check gate

Only requests with `HolidayType = "Annual Leave"` are checked against the
balance (sick/unpaid/compassionate leave don't draw down the annual
entitlement in most policies — adjust for your organization's actual rules).
For Annual Leave, the flow looks up the employee's current-year
`Holiday Balances` row and, if `TotalDaysRequested > RemainingDays`, sets
`ApprovalStatus = "Blocked - Insufficient Balance"` and emails the requester
**without** starting an approval — a manager is never asked to approve a
request that can't be granted. This check is enforced here rather than only
in the Power Apps form because a locally cached balance in the app can go
stale between page loads.

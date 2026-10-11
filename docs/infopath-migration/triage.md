# Form Inventory Triage

Source: `InfoPath_Form_Detailed_Summary_2.xlsx` (the organization's own build
log for all 43 live InfoPath forms), parsed into
[`form-inventory.csv`](./form-inventory.csv) and
[`workflow-inventory.csv`](./workflow-inventory.csv). Row/column totals in
both CSVs were cross-checked against the spreadsheet's own TOTALS row and
match exactly (188 pages, 4,296 fields, 3,771 rules, 3,040 conditions, 10,199
actions, 280 rebuild-days; workflows: 66 variables, 132 steps, 109 conditions,
235 actions, 195 rebuild-hours).

**"Days to rebuild" / "Hours to rebuild"** are the original estimates from
whoever built these InfoPath forms — a proxy for complexity, not a Power
Platform rebuild estimate. Treat them as a *relative* difficulty ranking
between forms, not a literal schedule.

Tiered below by the form's own days-to-rebuild figure, workflow effort shown
alongside for context (a form with a "quick" form but an expensive workflow —
e.g. Asset Disposal Request's 33 workflow-hours — is not actually quick
overall).

## Tier 1 – Quick wins (≤5 days) — 17 forms

Status: `Mis-Declared Empties`, `Vessel Condition Report`, and `Gritting Log`
have a prototype in `solutions/` (field lists inferred, pending the real
`.xsn` — see each solution's README). Everything else in this tier is not
started.

| Form | Days to rebuild | Pages | Fields | Rules | Conditions | Actions | Workflows | Workflow hours |
|---|---|---|---|---|---|---|---|---|
| CCTV Access Request | 4 | 4 | 75 | 44 | 30 | 72 | 2 | 7.0 |
| Damage Report | 4 | 3 | 54 | 33 | 26 | 58 | 1 | 7.5 |
| FuelTek Disc Request | 4 | 4 | 55 | 35 | 29 | 77 | 2 | 7.0 |
| Mis-Declared Empties ✅ prototype | 4 | 3 | 31 | 25 | 12 | 45 | 1 | 4.0 |
| Visitor Pass Request | 4 | 3 | 84 | 50 | 35 | 87 | 2 | 12.0 |
| Holiday Request | 4 | 3 | 38 | 29 | 20 | 63 | — | — |
| New Employee IDACs Request | 4 | 5 | 68 | 54 | 42 | 92 | — | — |
| Supplier Amendment | 4 | 4 | 74 | 54 | 45 | 46 | 1 | 1.0 |
| Vessel Condition Report ✅ prototype | 4 | 3 | 40 | 19 | 7 | 37 | — | — |
| Gritting Log ✅ prototype | 5 | 2 | 47 | 34 | 18 | 100 | 1 | 2.0 |
| Hospitality Booking Request | 5 | 3 | 73 | 59 | 49 | 133 | 2 | 10.5 |
| Jammed Twistlock | 5 | 3 | 80 | 58 | 44 | 155 | 1 | 5.0 |
| Optical Reimbursement Request | 5 | 3 | 46 | 46 | 34 | 133 | 3 | 10.0 |
| Return to Work Form | 5 | 2 | 54 | 43 | 29 | 91 | 1 | 3.0 |
| HP Europe Invoice Authorisation | 5 | 9 | 68 | 48 | 26 | 71 | — | — |
| Pre Invoice Waiver | 5 | 5 | 66 | 97 | 79 | 116 | — | — |
| Approval for Ad hoc Supplier Purchase | 5 | 3 | 66 | 42 | 34 | 136 | — | — |

## Tier 2 – Medium (6-8 days) — 14 forms

| Form | Days to rebuild | Pages | Fields | Rules | Conditions | Actions | Workflows | Workflow hours |
|---|---|---|---|---|---|---|---|---|
| Mobile Device Hardware | 6 | 3 | 104 | 78 | 60 | 320 | 2 | 8.0 |
| Tender Submission Form for eTender 2017 | 6 | 6 | 146 | 77 | 63 | 196 | 3 | 11.0 |
| Harwich Sales Invoice Request | 6 | 4 | 98 | 78 | 64 | 136 | — | — |
| Employee Starter Form | 6 | 9 | 104 | 76 | 54 | 173 | — | — |
| Rail Rejection Status | 7 | 4 | 91 | 84 | 73 | 209 | 1 | 5.0 |
| Claims Referral | 7 | 5 | 87 | 61 | 49 | 121 | 1 | 4.0 |
| Haulier Incident Tracker | 7 | 7 | 81 | 56 | 41 | 235 | 2 | 5.0 |
| LTP Sales Invoice Request | 8 | 4 | 98 | 78 | 64 | 221 | 1 | 4.0 |
| Customer Account Request | 8 | 6 | 141 | 129 | 106 | 193 | 2 | 8.0 |
| Finance Access and Data Request | 8 | 2 | 116 | 75 | 69 | 194 | — | — |
| Payroll Payment Adjustment Request | 8 | 6 | 62 | 67 | 51 | 184 | — | — |
| Professional Subscriptions Reimbursement Request | 8 | 3 | 60 | 42 | 31 | 176 | — | — |
| Contract Change | 8 | 4 | 61 | 64 | 54 | 203 | — | — |
| Employee Leaver Form | 8 | 10 | 115 | 127 | 102 | 281 | — | — |

## Tier 3 – Complex (9+ days) — 10 forms

| Form | Days to rebuild | Pages | Fields | Rules | Conditions | Actions | Workflows | Workflow hours |
|---|---|---|---|---|---|---|---|---|
| Supplier Contract Approval | 9 | 6 | 123 | 146 | 120 | 428 | 2 | 8.0 |
| Gift and Hospitality Form | 9 | 5 | 93 | 77 | 63 | 274 | — | — |
| Maximo Access Request | 10 | 5 | 144 | 159 | 133 | 491 | 2 | 7.0 |
| Mobile Device SIM Only | 10 | 3 | 121 | 107 | 87 | 575 | 2 | 7.0 |
| Proof of Learning | 10 | 6 | 402 | 213 | 186 | 512 | 1 | 4.0 |
| Capital Expenditure 2025 | 10 | 4 | 194 | 146 | 128 | 549 | 2 | 7.0 |
| Assignment Change Form | 10 | 5 | 228 | 261 | 226 | 721 | — | — |
| Supplier Additions | 11 | 4 | 236 | 252 | 191 | 659 | 1 | 15.0 |
| Asset Disposal Request | 12 | 8 | 202 | 314 | 253 | 882 | 2 | 33.0 |
| Stock Additions | 12 | 7 | 170 | 234 | 213 | 754 | — | — |

## Needs investigation (no effort estimate recorded) — 2 forms

| Form | Notes |
|---|---|
| Employee Part Shift Sickness | Row has 0 data connections and no field/rule counts recorded — likely dormant or a stub. Confirm it's still in active use before spending effort on it. |
| Issue of Leave Notification | Same as above — 0 connections, no counts recorded. |

## Suggested sequencing

1. ✅ **Start with Tier 1, lowest field/rule count first** (Mis-Declared
   Empties, Vessel Condition Report, Gritting Log) to validate the migration
   pattern and CI pipeline end-to-end on genuinely small forms before
   tackling anything with a workflow. Prototypes are in `solutions/` — field
   lists are inferred from the form names/domain context pending the real
   `.xsn` templates, so confirm those before treating any of the three as
   finished.
2. **Then Tier 1 forms with workflows** (CCTV Access Request, FuelTek Disc
   Request, Visitor Pass Request, Hospitality Booking Request, Optical
   Reimbursement Request) to validate the Power Automate approval pattern on
   low-risk forms.
3. **Confirm the two "needs investigation" forms** with the business before
   doing any work — they may not need migrating at all.
4. **Defer Tier 3 until the pattern is proven**, especially Asset Disposal
   Request (the single most complex workflow in the inventory at 33
   workflow-hours) and anything over ~400 fields (Proof of Learning,
   Assignment Change Form) — these likely need their Power Apps screens
   split up more than a 1:1 page mapping and should be scoped individually.
5. For every form, **the field list/rule logic must come from the actual
   `.xsn` template** (or a walkthrough) — this inventory only has counts.

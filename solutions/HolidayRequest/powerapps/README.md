# Holiday Request — Power Apps canvas app (source)

Source-controlled `.pa.yaml` in the same format produced by:

```sh
pac canvas pack --sources ./src --msapp ./build/HolidayRequest.msapp
```

See [`../../ITEquipmentRequest/powerapps/README.md`](../../ITEquipmentRequest/powerapps/README.md)
for the general notes on this format (build artifact vs. source, how to
regenerate). Don't hand-edit `.msapp`.

## Screens

| Screen | Purpose | Data source |
|---|---|---|
| `MyRequests.fx.yaml` | Shows the signed-in user's current balance and their past/pending requests | `Holiday Balances`, `Holiday Requests` |
| `NewRequestForm.fx.yaml` | Submit a new holiday request | `Holiday Requests` |

Both lists are added via `Data > Add data > SharePoint`, schema in
[`../sharepoint/list-schema.json`](../sharepoint/list-schema.json).

## Working-day calculation

InfoPath left "total days" as a free-text field the requester typed in by
hand, which regularly disagreed with the date range. `NewRequestForm`
computes it instead with:

```
=RoundUp(
    CountRows(
        Filter(
            Sequence(EndDatePicker.SelectedDate - StartDatePicker.SelectedDate + 1),
            Weekday(StartDatePicker.SelectedDate + Value - 1) <> 1 &&
            Weekday(StartDatePicker.SelectedDate + Value - 1) <> 7
        )
    ),
    0
)
```

i.e. it counts calendar days in the range and excludes Saturdays/Sundays. It
does **not** account for public holidays — if your organization keeps a
holidays calendar list, subtract matching dates from the count the same way.

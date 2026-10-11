# Vessel Condition Report — Power Apps canvas app (source)

Single screen (`ReportForm`): a header form plus a repeating defects table
built with a local collection (`colDefects`) that's written to the
`Vessel Condition Report Defects` child list on submit — the Power Apps
equivalent of an InfoPath repeating section. See
[`../../ITEquipmentRequest/powerapps/README.md`](../../ITEquipmentRequest/powerapps/README.md)
for the general notes on the `.pa.yaml` source format.

**No approval/notification flow** — the real form has none (see
[`../README.md`](../README.md)). Field list is inferred from the form name
and domain context, not extracted from the real InfoPath template.

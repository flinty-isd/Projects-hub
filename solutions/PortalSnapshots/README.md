# HPUK portal snapshots

Power Automate flows that keep the HPUK portal pages current from SharePoint lists.

The portals are single HTML files. Their figures live in an embedded **snapshot** block,
`<script id="embedded-snapshot" type="application/json">`. Until now, the only way to
refresh them was by hand: load CSV extracts, press **Save Snapshot HTML**, then upload the
downloaded file. These flows do the same job on a schedule:

1. Read the portal's lists.
2. Shape the rows into the JSON the portal expects.
3. Write that JSON into the portal's template.
4. Overwrite the published page.

The pages themselves never call SharePoint. That keeps them working as sandboxed SharePoint
HTML pages, where they can't read lists, and keeps them clear of the no-custom-script rule
(G-02).

| # | Flow | Writes | Reads |
|---|------|--------|-------|
| P1 | [Asset Management portal snapshot](powerautomate/flows/P1-Asset-Portal-Snapshot.json) | `hpuk-asset-management-portal.html` | Asset Register, Asset Requests |
| P2 | [Control Board snapshot](powerautomate/flows/P2-Control-Board-Snapshot.json) | `hpuk-project-management-control-board.html` | Programme Status (latest row), Board Decisions, Programme RAID (open), Migration Waves, Programme Gates |
| P3 | [IT Governance portal snapshot](powerautomate/flows/P3-Governance-Portal-Snapshot.json) | `hpuk-it-governance-portal.html` | Site Register and Decision Log (from the SharePointGovernance solution), Compliance Register, Governance Risks, Policy Exceptions, Governance Actions, Automation Run Log (last 30 days) |

All three run on **weekdays at 06:30 and 12:30 UK time**. Any of them can also be run on
demand from Power Automate. They do nothing until `PortalSnapshotsEnabled` = Yes.

The **SharePoint UI Design System** page has no flow. Its "data" is a page-builder
configuration, not list data, so its Save Snapshot HTML button stays the way to publish it.

## Layout

```
PortalSnapshots/
├── powerautomate/flows/   P1-P3 flow definitions
├── sharepoint/            list-schema.json: the 14 lists the flows read (12 created here, 2 from SharePointGovernance)
├── templates/             the three portal pages with an empty snapshot block, which the flows fill in
├── provisioning/          Provision-PortalSnapshots.ps1: creates the lists, uploads the templates
├── tools/                 check_templates.py: every page a flow writes has a valid template
├── DEPLOY-AND-TEST.md     deployment and test script
└── solution-config.json   solution name, version, environment variables
```

The shared validation and packaging tools are in `../SharePointGovernance/tools/`.

## How a run works

1. Read the template from `PortalTemplatesFolder` and the page as last published from
   `PortalPagesFolder`.
2. If the published page has a snapshot, keep it as *previous*. Two things use it:
   - P2 works out the week-on-week KPI deltas from it ("-3 improving", "+2 worsening").
   - P3 carries the SAM permission rows forward from it.
3. Read the lists. Every list read pages up to 100,000 rows.
4. Shape the rows with Select actions into the field names each portal already uses for its
   CSV imports.
5. Build the payload, then escape every `<`, so a value such as a closing script tag can't
   break the page. Save Snapshot HTML uses the same escaping.
6. Check that the template has the empty block and that the page is under SharePoint's 10 MB
   HTML limit, then write it with **Create file**. Create file replaces the page, adding a new
   version where the library keeps versions.

**What viewers see.** The Control Board and Governance portal show **SHAREPOINT LIST
SNAPSHOT**, with *Last Updated* and the lists as the source. The Asset portal keeps its own
labels (*Saved extract data*), and its source names the lists and flow P1.

**Manual workflows still work.** A viewer can still load a CSV and press Save Snapshot HTML.
Whatever they upload is replaced at the next flow run, so treat a manual upload as a stopgap.

## Things to know

- **Asset portal with an empty Asset Register.** The portal ignores a snapshot with no assets
  and shows its built-in sample data. Fill the list before switching P1 on.
- **SAM permissions** come from a CSV export (`latest-permissions-report.csv`), not a list, so
  P3 can't read them. Seed them once: open the published governance page, load the SAM CSV,
  press **Save Snapshot HTML** and upload that file over the published page. P3 carries those
  rows forward from then on. Repeat this whenever there is a new SAM export.
- **Guardrails** on the Control Board aren't in a list. They stay as built into the page.
- **Templates are the portals.** To roll out a new portal version, upload it to
  `PortalTemplatesFolder` with the same file name. Never upload a *saved snapshot* as a
  template: it has no empty block, and the flow then emails the support mailbox and writes
  nothing.
- **`PortalPagesFolder`.** Leave it at `/SitePages` to publish as SharePoint HTML pages
  ("Allow HTML files" must be on in that library). Set it to `/SiteAssets` to keep existing
  SiteAssets links working.
- **Environment variable names are unique.** Every variable is prefixed `Portal...` so it
  can't clash with the governance, news or PMO solutions in the same environment.
  `tools/check_solutions.py` (shared) checks this, and that no two solutions share a flow file
  name. Shared names would collide when two solutions sit in one environment.

## Environment variables

| Variable | Default |
|---|---|
| `PortalSiteUrl` | set after import |
| `PortalPagesFolder` | `/SitePages` |
| `PortalTemplatesFolder` | `/SiteAssets/PortalTemplates` |
| `PortalSnapshotsEnabled` | No |
| `PortalOwnerEmail` | set after import (shared mailbox) |
| `PortalSupportMailboxEmail` | empty |
| `PortalAssetSiteUrl`, `PortalBoardSiteUrl`, `PortalGovernanceSiteUrl` | set after import |

Connectors: SharePoint and Office 365 Outlook, both standard. Paging beyond 5,000 rows needs
the flow owner's Power Automate Premium licence. Run the flows under the named flow owner, as
the other solutions do (no service accounts, D-03).

## When a refresh fails

- **Failure email.** Every failure emails `PortalOwnerEmail` with the run link. The published
  page keeps its previous snapshot and *Last Updated* time, so viewers can see how old the
  figures are. Fix the cause and run the flow again.
- **"Template has no empty snapshot block".** Upload the template from `templates/` in the
  kit again.
- **"Too large".** Reduce what P3 publishes (for example, fewer Run Log days) or archive
  closed items.

## Validating and building

```
python solutions/SharePointGovernance/tools/validate_flows.py --root solutions/PortalSnapshots
python solutions/PortalSnapshots/tools/check_templates.py
python solutions/SharePointGovernance/tools/check_solutions.py
python solutions/SharePointGovernance/tools/build_kit.py --root solutions/PortalSnapshots --out dist
```

CI (`.github/workflows/portal-snapshots.yml`) runs all four. **Not yet run in a tenant.** The
flow output has been checked by feeding rows shaped like the flows' output through each
template and opening the result in a browser: all three portals render the data with no
errors. The flows themselves haven't run in Power Automate yet.

## Templates and the portals

`templates/` holds the portal files:

- the Asset Management portal as supplied
- the Control Board and IT Governance portal with Save Snapshot HTML added

If a portal changes, replace its template here and in `PortalTemplatesFolder`.
`check_templates.py` fails if a template has lost its empty snapshot block.

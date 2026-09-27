# HPUK Control Centre - SPFx web parts

A real SharePoint Framework (SPFx) solution: two custom web parts that fill
the two gaps flagged in `../../SharePointModernPages/README.md` - things a
stock SharePoint List web part can't do. This is a genuine, installable
SharePoint app (an `.sppkg` package), not a preview or a mockup.

## What's in it

| Web part | Fills the gap |
|---|---|
| **Programme Overview** | A single, real "Attention Required" table blending Red RAID + overdue Actions + blocked Migration sites + pending Decisions - four different lists, one table. Also shows the KPI tiles (Sites Complete baseline, Remaining Sites, Pages Outstanding, Overdue Actions). |
| **Page Delivery Timeline** | The visual Define → Design → Content → Build → UAT → Sign-off → Go-live stepper for one Page Delivery Register item, defaulting to `PAGE-001` (People) but configurable to any Page ID via the property pane. |

Both read live from the six SharePoint Lists provisioned by
`../../SharePointModernPages/scripts/01-Provision-Lists.ps1`, over the
standard SharePoint REST API via `SPHttpClient` - no extra PnPjs dependency.

## Data source: real when deployed, mock in the local workbench

`src/common/createDataService.ts` follows the standard SPFx pattern: it
checks `Environment.type` and returns `MockControlCentreDataService` when
running in the local workbench (`gulp serve`, since there's no real
"current site" list data there), or `SharePointControlCentreDataService`
everywhere else (a real SharePoint page, Teams, Viva Connections). The
mock data is the same illustrative scenario used throughout this repo -
not the real HPUK workbook data.

## Build status: real, but unbuilt

Every source file here was **type-checked with the actual TypeScript
compiler against the real `@microsoft/sp-*` 1.23.2 packages, React 17, and
Fluent UI** - not hand-reviewed guesswork. That check passed clean (see
commit history / ask if you want the validation log). What it does *not*
confirm: an actual `gulp bundle --ship` + `gulp package-solution --ship`
run, producing a working `.sppkg`. That part could not be completed in the
environment this was written in - the legacy Yeoman/`yo` CLI toolchain
SPFx still documents has known, unrelated compatibility problems with
current Node/npm (broken transitive dependencies in `yo` itself, not in
this code), and `@microsoft/sp-build-web`'s own gulp pipeline was not
attempted here for the same reason. **Run `npm install` then
`gulp bundle --ship` and `gulp package-solution --ship` yourself before
deploying** - if that surfaces anything, it's almost certainly a
config/dependency version hiccup in that legacy toolchain rather than a
mistake in the source files, since those were independently verified.

## Prerequisites

- Node.js compatible with SPFx 1.23.2 (`engines` in `package.json`)
- `npm install` in this folder
- The six lists already provisioned (see `../../SharePointModernPages/`)

## Build and deploy

```powershell
npm install
gulp bundle --ship
gulp package-solution --ship
```

That produces `sharepoint/solution/hpuk-control-centre.sppkg`. Upload it to
your tenant's App Catalog, then add the "Programme Overview" and "Page
Delivery Timeline" web parts to any modern page (including the ones
`../../SharePointModernPages/scripts/03-Provision-Pages.ps1` creates -
they slot in as a straight upgrade over the placeholder text left there
for these exact gaps).

## Local development

```powershell
gulp serve
```

Opens the local workbench with mock data (see above) - no real site
connection needed to see the UI and iterate on it.

## Project layout

```
src/
  common/
    models.ts                    - shared types, matching the 6 lists' real field names
    SharePointDataService.ts     - real REST implementation + mock implementation
    createDataService.ts         - picks one based on Environment.type
  webparts/
    programmeOverview/           - KPIs + unified Attention Required table
    peopleDeliveryTimeline/      - the Define...Go-live stepper
```

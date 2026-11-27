# HPUK portal snapshots: deploy and test

Do every step on test sites and a dev environment first. Production repeats the same steps
from the same deployment kit (check `MANIFEST.json`), under the rules in the
[Power Platform deployment plan](../POWER-PLATFORM-DEPLOYMENT.md).

## 1. Sites, lists and templates

1. Decide on four sites:
   - **portal site**: where the pages are published, e.g. the IT site
   - **asset site**
   - **Control Board site**
   - **governance site**: the IT Enterprise Governance site, where the SharePointGovernance
     solution's Site Register and Decision Log already are

   Sites can be the same.
2. Run, as an owner of each site:

   ```powershell
   ./provisioning/Provision-PortalSnapshots.ps1 -PortalSiteUrl <portal> -AssetSiteUrl <asset> `
       -BoardSiteUrl <board> -GovernanceSiteUrl <governance> -ClientId <pnp-app-id> -Interactive
   ```

   Check:
   - the 12 lists exist with versioning on
   - the script reports the Site Register and Decision Log as found with the columns P3 reads
   - the three templates are in `SiteAssets/PortalTemplates`
3. In the portal site's **Site Pages** library, go to *Library settings > File types* and turn
   on **Allow HTML files**. Skip this if you'll publish to `/SiteAssets` instead.
4. Load real data:
   - Asset Register and Asset Requests
   - one Programme Status row, then Board Decisions, Programme RAID, Migration Waves and
     Programme Gates
   - the governance registers
5. **Permissions.**
   - The flow owner needs Read on the source lists and Edit on the portal site's pages and
     templates folders.
   - Everyone else needs Read on the pages only. Restrict the templates folder to the PMO and
     IT owners.

## 2. Import

1. Under the **named flow owner** (no service account), create SharePoint and Office 365
   Outlook connections.
2. Import `PortalSnapshots_<version>.zip` and bind both connection references.
3. Under *Environment variables*, set:
   - `PortalSiteUrl`
   - `PortalOwnerEmail`
   - the three source site URLs
   - optionally `PortalPagesFolder` and `PortalSupportMailboxEmail`

   Leave `PortalSnapshotsEnabled` at No.
4. Turn on P1, P2 and P3.

## 3. Tests

| # | Test | Expect |
|---|------|--------|
| T1 | Run P1 with `PortalSnapshotsEnabled` = No | Succeeds and writes nothing |
| T2 | Set it to Yes and run P1 | `SitePages/hpuk-asset-management-portal.html` is written. Open it: *Last Updated* is this run's time, Source names the Asset Register and flow P1, and the counts match the lists |
| T3 | Run P2 | The Control Board shows *SHAREPOINT LIST SNAPSHOT*. Decisions are in score order, only open RAID items appear, and the KPI tiles match the latest Programme Status row and the RAID counts. Deltas read "0 steady" on the first run |
| T4 | Close one Red risk and run P2 again | Red risks down by 1, delta "-1 improving" |
| T5 | Run P3 | The Governance portal shows *SHAREPOINT LIST SNAPSHOT*. The Site Register tab matches the Site Register (archived sites excluded), with ports read from the site URL codes. Each register's source names its list. SAM still shows the built-in sample |
| T6 | Seed SAM: open the published governance page, load the SAM CSV, *Save Snapshot HTML*, upload over the page. Run P3 | The SAM rows from the CSV are still there after P3 |
| T7 | Put `</script>` in an asset title and run P1 | The page opens normally and the title shows the text literally |
| T8 | Upload a *saved snapshot* as the P1 template and run P1 | Nothing written; "template has no empty snapshot block" email to `PortalOwnerEmail`. Put the kit template back |
| T9 | Point `PortalAssetSiteUrl` at a wrong URL and run P1 | *Flow failed* email; the published page unchanged |
| T10 | Open each published page on a phone and as a SharePoint HTML page | Readable. The page makes no data calls (check the browser's network panel) |
| T11 | Wait for the 06:30 and 12:30 weekday runs | Both run and *Last Updated* moves on |

## 4. BAU

- **Daily:** the portal mailbox owner checks P1-P3's run history. The failure email only
  covers runs that started.
- **When there's a new SAM export:** reseed SAM as in T6.
- **New portal version:** replace the template in `templates/` (CI checks it), rebuild the
  kit, then upload it to the templates folder.

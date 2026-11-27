# SharePoint News and Notices

The build for **HPUK SharePoint Online News Design v1.2**: two communication
sites (HPUK News and Other News) aggregated on the intranet home, with
expiry, a weekly port roundup and urgent notices automated in Power Automate.
It uses standard modern pages only, with no SPFx.

> **Release status, 22 November 2026: production activation is ON HOLD.**
> An independent release-readiness review of 1.5.0.0 found a recovery
> instruction that could mark an unsent notice as sent (the failure email
> said a *Reserved* row had been sent), and that the news deployment and
> test materials weren't supplied with the solution. 1.6.0.0 corrected the
> instruction (a Reserved row is never proof of delivery) and ships as a
> deployment kit (this README, the scripts, schema, pages, taxonomy and a
> `MANIFEST.json`). A further finding on 23 November 2026: C2 took its week
> from the time it ran, so a failed roundup resubmitted after the next
> Monday processed the new week and left the failed one outstanding. 1.7.0.0
> takes the week from the run's scheduled time and adds `RoundupReplayWeek`
> (see *Replaying a roundup week*). The hold lifts only when the Testing
> table passes in test on 1.8.0.0 (expired posts are now archived, decision 6c) (including *Reserved, never sent* and
> *Roundup across the Monday boundary*), the reviewer has re-reviewed
> `SharePointNews-DeploymentKit_1_7_0_0.zip`,
> and the release decision is recorded. Don't import into production before
> then.

| Part | What it is |
|------|-----------|
| [`sharepoint/list-schema.json`](sharepoint/list-schema.json) | Every list and column on both sites. The single source for provisioning and flow validation |
| [`provisioning/Provision-NewsSites.ps1`](provisioning/Provision-NewsSites.ps1) | PnP script that applies the schema, views, permissions (with page approval off) and the Publisher Guide page to both sites |
| [`provisioning/Set-NewsRetention.ps1`](provisioning/Set-NewsRetention.ps1) | Purview retention policy: 7 years on both sites |
| [`pages/Publisher-Guide.html`](pages/Publisher-Guide.html) | Content of Publisher-Guide.aspx on HPUK News |
| [`powerautomate/flows/`](powerautomate/flows) | C1 expiry, C2 weekly port roundup, C3a/C3b urgent notice (one per site) |
| [`pages/News-Archive-Page.md`](pages/News-Archive-Page.md) | The News archive page on each site: where expired posts stay readable (view, List web part, checks) |
| [`pages/HPUK-News-Post-Template.md`](pages/HPUK-News-Post-Template.md) | Step-by-step build of the *HPUK News post* page template (and *Other News post*) in the SharePoint editor |
| [`C1-WALKTHROUGH.md`](C1-WALKTHROUGH.md) | One-page walkthrough of C1 expiry: each step, a normal day, what each email means, how to check it |
| [`taxonomy/`](taxonomy) | Department and Category term sets (term-store import files) |
| [`skills/hpuk-image-banner/`](skills/hpuk-image-banner) | SharePoint site skill for every image in a News post (banner, thumbnail and body web parts): works out the size, crop and focal point, with a Paint recipe and READY checks. Optional Python version in [`tools/image-banner/`](tools/image-banner) |
| [`skills/hpuk-news-flows/`](skills/hpuk-news-flows) | SharePoint site skill for the News flows: setup, testing expiry and diagnosing failed runs, with the sites' column names and settings. Instructions only |
| [`solution-config.json`](solution-config.json) | Solution package settings: environment variables and connection references |

## Design decisions

The design leaves several points open. Most of them change how the build
works, so the build takes a position on each. Each one is easy to reverse
if Communications or IT decide otherwise.

| # | Design v1.2 says | The build does | Why |
|---|------------------|----------------|-----|
| 1 | Port blank means all ports | **Port is required**, with an explicit *All ports* choice | A forgotten Port on an urgent notice would otherwise email every port |
| 2 | A Managers-targeted post must not be emailed to a whole port; either route or exclude it | **Audience-targeted posts are excluded** from the roundup and from urgent broadcasts. C3 logs *Skipped - audience targeted* and tells Communications | Audience targeting is personalisation, not a distribution list. Port routing can't express "managers at Felixstowe" |
| 3 | Dispatch key uses an "agreed publication event" | Key = `urgent\|site\|page ID\|r<NotificationRound>\|port#<row ID>\|channel`, where row ID is the Comms Distribution row's ID (from 1.4.0.0), so two rows for the same port are two destinations. **NotificationRound** is a page column (default 1) | Edits never resend. Communications sends a correction by raising the round and resetting UrgentSent |
| 4 | Don't assume a metadata update leaves the published page unchanged | C1 and C3 update Status, Show in News and UrgentSent with **ValidateUpdateListItem** (`bNewDocumentUpdate`): no new version, no draft | A normal update leaves a published news page with a pending draft |
| 5 | UrgentSent is not the sole duplicate control | The trigger runs only for **major versions** (`x.0`) with UrgentSent = No, one at a time. Each port and channel is **reserved** in the Delivery Log before sending (see the safeguards below) | Retries send only definite failures; an unknown outcome waits for a person. Setting UrgentSent cannot re-trigger the flow |
| 6 | Expiry boundary to confirm | **Expiry Date is the last current day.** C1 runs 06:00 UK time and expires dates before today (UK date, so BST is handled) | Matches the design's proposed rule |
| 6a | (found in testing) The Site Pages columns were made by hand, not by the provisioning script | The flows use the sites' own columns: **Show in News** (Yes/No, internal `ShowinNews`) instead of Status Live/Expired, **Expiry Date** (internal `Expiry_x0020_Date`), **Include in Weekly Roundup** (`Include_x0020_in_x0020_Weekly_x0020_Roundup`) and **Strategy Theme** (`Strategy_x0020_Theme`, a Choice column; theme grouping matches Choice values as well as managed metadata labels). Other News has different internal names for three of these: `ExpiryDate`, `StrategyTheme` and `InRoundup` (added by hand there), and the flows use each site's own names. **Urgent** and **Port** keep their names; **UrgentSent** and **NotificationRound** are added by hand. C1 sets Show in News to No on any published post past its Expiry Date unless it is already No, **blank included**. Set both columns as described under Testing. The News web part filter can't use Yes/No columns, so a **Status** Choice column (Live, Expired; default Live) is added by hand on both sites for the web parts to filter on; C1 sets it to Expired together with Show in News | PowerShell can't be run, so the flows follow the sites. C2 and C3 also need the Comms Distribution and Delivery Log lists on HPUK News, created by hand with the internal names in `sharepoint/list-schema.json` |
| 6b | (found in UAT) Status and Show in News alone don't hide an expired post: hub and home-page news, the SharePoint start page and app, Viva Connections and the news digest ignore them, and search lags | **C1 unpublishes expired posts** (back to draft) after setting Status Expired and Show in News No, and confirms it by reading the page back. Site Pages needs draft versions with drafts visible only to editors, so readers can't open an expired post | Chosen by the service owner (option A). Links to an expired post stop working for readers; editors still see it; nothing is deleted and republishing restores it |
| 6c | (27 November 2026) Expired posts must stay readable somewhere, separately from current news | **C1 archives instead of unpublishing** (1.8.0.0, replaces 6b's unpublish): it checks the page out, sets Status Expired, Show in News No and **PromotedState 0** (an ordinary page, no longer a news post), and checks it in published. The post leaves every news feed, hub news, Viva and the roundup, and is listed on each site's **News archive** page, where readers can open it. Confirmed by read-back. Posts unpublished before 1.8.0.0 stay hidden until `ArchiveUnpublishedExpired` is set to Yes for one run | Chosen by the service owner: every expired post stays readable by the site's readers. To remove a notice completely, a publisher unpublishes it by hand |
| 7 | Frontline route for generic accounts | **Out of this build.** PID v3.1 prohibits shared and generic accounts in SharePoint. Its approved routes are the Employee App (view-only staff) and display-mode pages (screens) | Avoids a design that breaks the access model |
| 8 | Everyone except external users as Visitors, to confirm | **A scoped reader group** is required by the script, and EEEU is never used | The tenant is shared with a peer company |
| 9 | Compare the built-in news digest with C2 | C2 is built, with **Include in Weekly Roundup** and per-port routing that the built-in digest can't do | Pilot both. If the built-in digest is good enough, turn C2 off |
| 10 | Classification and governance of the sites | Request both sites through the **governance Site Requests list** (flow 03), Sensitivity *General*, with named primary and secondary owners | Puts the sites in the Site Register, so they get 90-day access reviews |

### Business decisions (confirmed 22 October 2026)

| Decision | Confirmed | Where it's applied |
|----------|-----------|--------------------|
| Ports | **Felixstowe, Harwich, Thamesport** (plus *All ports* on posts) | `list-schema.json`: Port choices on posts and Comms Distribution |
| Who can send urgent notices | **Chloe, Rachel and Toby** | `UrgentPublisherEmails` environment variable. C3 sends only when the person who published this version (the page's last editor) is on the list, matched exactly by address, not the page's original author; anything else is logged as *Skipped - not an urgent publisher* and Communications is told |
| Page approval | **None. Publishers are pre-approved** (changed 23 October 2026; this replaces HR approving every page) | Content approval stays off on Site Pages (the provisioning script turns it off if it was on). A published page is live straight away, and an urgent post by Chloe, Rachel or Toby alerts as soon as it is published. Membership of the publisher groups is the control, so keep them to trained, named publishers |
| Retention | **7 years** from creation, on both sites | `provisioning/Set-NewsRetention.ps1`: a Purview retention policy. Nothing is deleted automatically at the end unless the records owner asks for `-DeleteAfterRetention` |
| Support mailbox | **Communications shared mailbox**, Intercommunications@fdrc.co.uk (changed 22 November 2026; replaces Nigel Bell's own address) | `SupportOwnerEmail` environment variable: receives all flow failure alerts. Failures go to the shared mailbox, never to one person, so they are seen during absences |
| Urgent notices for staff without a licence | **Updated separately in each area** (26 October 2026). About 1,500 operational staff use the Base8 CMS in the Employee App and receive no email or Teams alert | Outside these flows: C3 alerts licensed staff by email and Teams only. Each area posts its own urgent notices for unlicensed staff through its local route (Base8 CMS, noticeboards, supervisor briefings). Nothing in the build changes |
| Images and video | Pictures added in the page (banner image and Image or Image gallery web parts) with alt text; video uploaded to a **News Videos** library on each site and shown with the File and media web part, playing through Stream. No external video embeds (G-06). Emails, Teams alerts and the roundup carry text and a link only | `list-schema.json` and `Provision-NewsSites.ps1`: the News Videos library (major versions, site permissions, a Captions checked column). Publisher Guide: Images and video section |
| Strategy themes | **Option A** (26 October 2026): an optional **Strategy theme** label with Our People, Our Business, Our Environment and One TEAM, separate from Department and Category. A post can carry more than one | `taxonomy/TermSet-StrategyTheme.csv` and a multi-value `StrategyTheme` column on Site Pages. Theme sections on the intranet home filter on it. C2 groups the Monday roundup by theme when `RoundupGroupByTheme` = Yes (default No). Communications supplies each theme's wording, including the One TEAM principles |
| Departments and categories | **13 departments and 16 categories, confirmed for UAT** (24 October 2026). Department is who owns a post; Category is what it is about | [`taxonomy/`](taxonomy): `TermSet-Department.csv` and `TermSet-Category.csv` for the term store, and `terms.json` with each term's definition and examples. The Safety section filters on Category **Health and Safety**. Communications gives final sign-off after UAT; changes after that are made in the term store |

### Safeguards added after the independent review (24 October 2026)

An independent review of the design (with a Power Apps source package)
raised four points this build has adopted. Its other proposals were not
adopted: a Power Apps publisher console (the design excludes a custom app;
Quick Links on the Publisher Guide page do the same job), extra approval
flags on each post (publishers are pre-approved), and a blank Port meaning
all ports (decision 1).

| Safeguard | How it works |
|-----------|--------------|
| **Reserve before sending** | The Delivery Log Title (the dispatch key) is unique and indexed. Before each email or Teams post the flow writes a *Reserved* row, and sends only if that succeeds. The send has no automatic retry. The row then becomes *Sent*; *Failed* if the provider definitely rejected it (a 4xx other than 408/429); or *Reconcile* if the outcome is unknown (a timeout, 5xx or throttling). Only *Failed* rows are ever retried. A person checks *Reconcile* and *Reserved* rows (the **Needs checking** view) with the recipient. A *Reserved* row is **not** proof of delivery: the run may have stopped after reserving and before sending. Set a row to *Sent* only when the recipient confirms the message arrived; otherwise set *Failed* to allow a resend. Setting *Sent* without that check can leave a notice unsent for good, and for C3 it lets UrgentSent become Yes |
| **Master switches, off by default** | `DispatchEnabled` = No: C2 and C3 send nothing (runs show as Cancelled). `ExpiryWritesEnabled` = No: C1 changes nothing and emails the support mailbox the pages it would have expired. Turn each on only after it has been proven, and set `DispatchEnabled` back to No to stop new runs (see **Stopping** for a run already going) |
| **Failure alert** (1.5.0.0) | Each flow's steps sit in a main scope: an error no step handles (a list that can't be read, a connection failure) sends the support mailbox one high-importance *Flow failed* email with the run link and the failed steps. A run that never starts sends nothing: the support mailbox's owners check each Monday that C1 ran every day and C2 ran that morning. List reads page up to 100,000 rows (Power Automate Premium; 5,000 without it) |
| **Urgent go-live date** | `UrgentGoLiveDate`: C3 ignores posts first published before it, so editing an old or migrated post never sends an alert. Set it once at go-live and don't move it |
| **One destination, one key** (1.4.0.0) | Keys name the Comms Distribution row (`port#ID`), not just the port, so two rows for the same port each get their delivery and never block each other. Changing a row's address keeps its key: that week's roundup or that notice isn't sent again to the new address. The address used is read from the row just before sending and written to the Delivery Log |
| **Retry claims** (1.4.0.0) | A *Failed* row is claimed for a retry with an ETag check (`If-Match`): if another run changed the row after this run read it, the claim fails with 412, nothing is sent and support is told. C2 also runs one at a time (C3 already did), so a resubmitted roundup waits for the running one to finish |
| **Stopping** | `DispatchEnabled` is read when a run starts, so setting it to No stops **new** runs only. To stop a run already going, set the destinations' `Enabled` to No in Comms Distribution: each row is read again just before it is sent, and a switched-off row is skipped and reported. To stop at once, also cancel the run in the flow's run history. Then open the Delivery Log **Needs checking** view: a row left *Reserved* by a cancelled run may or may not have gone; check with the recipient: Sent only if it arrived, otherwise Failed. Turning the flow off doesn't stop a run already going |
| **Fixed roundup week** (1.7.0.0) | C2 covers Monday 00:00 to Monday 00:00 UK time, the week before the run, and works the week out from the run's **scheduled** time, not the time it executes. A late run, or a run resubmitted from run history, keeps its own week and reuses the same dispatch keys, so nothing is sent twice. To resend a week whose *Failed* rows are still outstanding after the next Monday (for example a resubmit that Power Automate started afresh), use **Replaying a roundup week** below: never rely on a later run to pick up an earlier week |

## How it works

```mermaid
flowchart LR
  P([Publisher publishes a post]) --> SP[("Site Pages<br/>both sites")]
  SP -- "daily 06:00: Expiry Date passed" --> C1["C1 Expiry"] -- "Expired, no longer a news post:<br/>News archive" --> SP
  SP -- "Mondays 07:00: Show in News, Include in Weekly Roundup, last 7 days" --> C2["C2 Port roundup"]
  SP -- "published major version, Urgent, not yet sent,<br/>by an urgent publisher" --> C3["C3 Urgent notice"]
  CD[("Comms Distribution<br/>port → email group, Teams channel")] --> C2 & C3
  C2 & C3 -- "reserve key, then send" --> OUT[/"Email from Comms mailbox<br/>Teams channel post"/]
  C2 & C3 -- "Reserved, then Sent / Failed / Reconcile" --> DL[("Delivery Log")]
  C3 -- "all sent: UrgentSent = Yes" --> SP
```

## Deploying

Deploy from the **deployment kit** (`SharePointNews-DeploymentKit_<version>.zip`,
CI artifact *SharePointNews-DeploymentKit*, or
`python tools/build_kit.py --root solutions/SharePointNews` from the repo).
It holds the importable solution, this README (deployment, testing,
troubleshooting), the provisioning and retention scripts, the list schema,
the Publisher Guide page, the term sets, the skills, the validation tools and
the Power Platform deployment plan, with a `MANIFEST.json` of SHA-256
checksums and the source commit. Check the checksums before you start and
keep the manifest with the test evidence. From the unpacked kit folder,
`python tools/validate_flows.py --root .` checks the flows and
`python tools/build_solution.py --root . --out out` rebuilds the solution
for comparison with `solution/`. (The dashboard validator is governance-only
and isn't in this kit.)

1. **IT foundations.** Request both sites through the governance Site
   Requests list. Associate both with the intranet hub, and designate HPUK
   News as an organisation news site. Create these Entra security groups:
   - HPUK readers (scoped to the HPUK population)
   - HPUK News publishers
   - Other News publishers
   - news configuration maintainers

   Also create the Department, Category and Strategy theme term sets by
   importing `taxonomy/TermSet-Department.csv`, `taxonomy/TermSet-Category.csv`
   and `taxonomy/TermSet-StrategyTheme.csv` into the Communications term group (SharePoint admin centre → Term store
   → Communications → Import term set), and a shared mailbox
   for sending, with Send As for the **named news flow owner** (no service
   or shared account, D-03; see the
   [deployment plan](../POWER-PLATFORM-DEPLOYMENT.md#identities)).
2. **Provision.** Run `provisioning/Provision-NewsSites.ps1` with the two site
   URLs, the group object IDs, the flow
   owner's UPN and `-ClientId` (the Entra app PnP signs in with; required for
   `-Interactive` too). Existing columns are compared with the schema and
   any difference (type, required, default, choices) is listed as drift;
   `-FixDrift` corrects defaults, required and missing choices (for example a
   blank Status or Show in News default) but never a column's type or an extra
   choice. Permissions are only checked on a normal run: the restricted
   lists, broad claims (Everyone, Everyone except external users) and
   individual grants are reported, never removed. `-RepairPermissions`
   re-applies the list restrictions, keeping item-level permissions unless
   `-ClearItemPermissions` is also given. The script ends with an error while
   any drift is left, so a clean finish means the sites match. Add `-CreateTemplates` to build the page templates *HPUK
   News post* and *Other News post* (header, then Summary, Main content,
   Action required and deadline, Attachments, Contact; the Summary hint
   reminds publishers to fill in Page details before publishing); run it once per
   site, and use `-RefreshTemplates` to rebuild them after a layout change.
   The templates have no author byline, so posts read as from the site
   rather than the publisher (who published stays in version history).
   Afterwards open each template, add a banner image, check the byline is
   empty and republish. Then have a Purview compliance admin run
   `provisioning/Set-NewsRetention.ps1` for the 7-year retention: first with
   no switches, which only compares the tenant with the intended policy and
   prints a plan; then with `-Apply -ApprovalReference <records owner's
   decision ID>`. An existing rule with a different duration, action or start
   date is reported and left alone unless `-UpdateExistingRule` is given; a
   site excluded from the policy stops the run. It reads the policy back and
   fails on a distribution error; run the check again until Distribution
   shows Success (up to 7 days).
3. **Manual site settings.** These have no supported cmdlet:
   - Site Pages → *Settings → Audience targeting* → **On**, on both sites.
   - Page templates, only if you didn't use `-CreateTemplates`: build
     *HPUK News post* and *Other News post* by hand, following
     [`pages/HPUK-News-Post-Template.md`](pages/HPUK-News-Post-Template.md)
     (sections Summary, Main content, Action required and deadline,
     Attachments, Contact; no author byline; saved as a template).
   - Home pages: set up the News web parts as listed below, and build the
     **News archive** page on each site ([`pages/News-Archive-Page.md`](pages/News-Archive-Page.md)).
4. **Comms Distribution.** Add one row per port, with its email group, Team ID
   and Channel ID. For a company-wide roundup, add a row with Port **All
   ports** (for example an all-HPUK list or a corporate Teams channel): it
   receives every post in the Monday roundup but never an urgent alert, since
   each port already gets All ports alerts. Anyone in both a port list and the
   company-wide list gets two roundups. Set `Enabled` = No until each destination has been tested.
5. **Import the flows.** Build the package and import it as in
   [the governance README](../SharePointGovernance/README.md#importing):
   ```
   python solutions/SharePointGovernance/tools/build_solution.py --root solutions/SharePointNews
   ```
   It needs three connections (SharePoint, Office 365 Outlook, Microsoft
   Teams), signed in as the named news flow owner, and twelve environment variables,
   including the Communications shared mailbox (`SupportOwnerEmail`) and the urgent publishers'
   addresses, separated by semicolons (`UrgentPublisherEmails`). None is
   mandatory at import: after importing, open the solution → **Environment
   variables** and set the four whose description starts "Set after import".
   The two site URLs come preset for the `hphneu` tenant
   (`https://hphneu.sharepoint.com/teams/hpuk-pof-HPUKNEWS` and
   `.../hpuk-pof-OTHERNEWS`); only override them in a test environment. If a
   site URL has a **Current value**, it replaces the preset, so check its
   spelling or remove it.
   To get a report after every expiry run, put your address in
   `ExpiryReportEmail` (empty means no report). C1's emails, like the
   roundup and urgent notices, are sent from `CommsSenderMailbox`, so the
   named flow owner needs **Send As** on that shared mailbox.
   Leave `DispatchEnabled` and `ExpiryWritesEnabled` at No and
   `UrgentGoLiveDate` at its default for now.
   CI also builds it: download the artifact *SharePointNews-solution*.
6. Turn on **C1** first, then **C3a/C3b**, then **C2**. With the switches
   off nothing is sent or changed yet.
7. **Switch on, in this order:**
   1. After a few C1 dry-run emails list the right pages, and expiry has
      been checked on a test page, set `ExpiryWritesEnabled` to Yes.
   2. Set `UrgentGoLiveDate` to the go-live date and time in UTC, for
      example `2026-11-02T00:00:00Z`.
   3. When each Comms Distribution row has been tested (`Enabled` = Yes),
      set `DispatchEnabled` to Yes.

### News web part settings

| Page | Web part | Source | Filter | Layout |
|------|----------|--------|--------|--------|
| HPUK News home | News | This site | Page properties: Status = Live | Top story |
| HPUK News home | News (Safety) | This site | Status = Live **and** Category = Health and Safety | List |
| Other News home | News | This site | Status = Live | Side-by-side |
| Intranet home | News (main) | HPUK News | Status = Live; audience targeting on | Top story |
| Intranet home | News (secondary) | Other News | Status = Live; audience targeting on | List, lower on the page |
| Intranet home (optional) | News, one per theme: Our People, Our Business, Our Environment, One TEAM | HPUK News and Other News | Status = Live **and** Strategy theme = that theme | Side-by-side or carousel |

| HPUK News and Other News | **News archive** page: List web part showing the Site Pages **News archive** view | This site | Status = Expired (in the view) | List, newest first; see [`pages/News-Archive-Page.md`](pages/News-Archive-Page.md) |
| Intranet home (optional) | Quick link *News archive* to each site's archive page | — | — | — |

If the News web part can't filter on the managed metadata Category in your
tenant, use a Category view of Site Pages in a Highlighted content web part
for the Safety section instead.

## Testing

Use test sites, test groups and safe test recipients first: the PoC set-up
is not the production permission model.

| Test | Pass condition |
|------|----------------|
| Expiry | A post with yesterday's Expiry Date, after the 06:00 run: Status Expired, Show in News No, **no longer a news post** (Page details shows it as a page), still published; listed under *Archived* in the report. It has gone from the site and intranet home news, hub news and the next roundup, and appears on the **News archive** page, where a reader account can open it. A blank date stays as news. Adding the post to a C3 test: archiving it sends no urgent alert |
| Expiry re-run | Run C1 again straight away: the archived post isn't picked up again and nothing changes |
| Expiry, earlier unpublished posts | A past-expiry news post that is a draft (unpublished earlier) is listed under *left hidden* and not changed. Set `ArchiveUnpublishedExpired` = Yes and run C1: it is archived (published as a page, on the News archive). Set it back to No |
| Expiry failure leaves no checkout | In a test copy, make *Update fields* fail (e.g. a column name that doesn't exist): the page is reported, is **not** left checked out, and is unchanged |
| Expiry checked out | Check a past-expiry post out to another account, run C1: it is reported as checked out and left alone |
| Expiry site locked | On a locked or read-only site, C1 reports each page with SharePoint's message (*Additions to this Web site have been blocked*) and carries on |
| Site Pages columns | On each site: Library settings → **Show in News**: default **Yes**, then **OK** (re-save even if it already says Yes). **Expiry Date**: Date and Time Format **Date Only**. A new News post must show Show in News = Yes in Page details before you publish it. In grid view, set any blank Show in News to Yes. Create **Status** (type the name exactly): Choice, Live and Expired, default **Live**, **OK**, then open it again and **OK**; set any blank Status to Live. **Versioning settings**: *Create major and minor (draft) versions*, and *Draft item security*: **Only users who can edit items** (keeps work-in-progress drafts away from readers; C1 itself no longer depends on it) |
| Urgent, happy path | One email and one Teams post per matching port. Delivery Log has one *Sent* row per port and channel. UrgentSent = Yes |
| Urgent, edit | Editing and republishing a sent urgent post sends nothing |
| Urgent, correction | Round + 1 and UrgentSent = No, then republish. Exactly one new alert per destination |
| Urgent, partial failure | Disable one Teams channel. The other sends succeed, the failure is logged as Failed, support is alerted and UrgentSent stays No. Resubmitting the run sends only the failed one |
| Unknown outcome | Force a timeout or 5xx on one send (e.g. an unreachable mailbox). The row is logged as Reconcile and appears in *Needs checking*; resubmitting the run does **not** resend it until the row is set to Failed |
| Concurrent runs | Resubmit the same urgent run twice at once. Each destination is sent once; the second reservation fails on the unique key and nothing is sent |
| Concurrent retries | Set one roundup row to Failed and resubmit the C2 run twice at once: the second waits for the first (one run at a time) and then finds the row Sent, so the port gets one roundup. Edit a Failed row by hand after a run has read it but before it claims it (or test the claim with a stale ETag in a copy of the flow): the claim fails with 412 and nothing is sent |
| Two rows, one port | Two enabled Comms Distribution rows for the same port with different addresses: each gets the roundup and the urgent alert, with its own Delivery Log row (`port#ID`) |
| Changed address | Change a row's address after its roundup was sent and re-run C2 the same week: nothing is sent. Set its row to Failed and re-run: it goes to the new address, and the Delivery Log's Destination shows the new address |
| Sent, then log failure | Make the Delivery Log read-only for the flow identity just after a send (or break Mark sent in a copy): the row stays Reserved, support is told it was sent but not logged, and a re-run doesn't resend it |
| Failure alert | In a test copy of C2, change Get destinations to a list name that doesn't exist and run it: the run fails and the support mailbox gets one *Flow failed* email naming the step |
| Paging | With 150 expired test posts, one C1 run processes all of them |
| Reserved, never sent | In a test copy of C2, add a Terminate after *Email Reserve new* and run it: the row stays Reserved and nothing is sent. The alert and the Needs checking view treat it as unconfirmed; the tester confirms nothing arrived, sets Failed, and the next run sends it once |
| Stop during a run | With several destinations, start C2 and set the later rows' `Enabled` to No: those rows are reported as switched off and not sent. Cancel a run in run history mid-way: any row left Reserved shows in *Needs checking* |
| Switches off | With `DispatchEnabled` = No, publishing an urgent post and running C2 send nothing (runs show Cancelled). With `ExpiryWritesEnabled` = No, C1 emails a dry-run list and changes no page |
| Go-live date | Editing and republishing an urgent post first published before `UrgentGoLiveDate` sends nothing |
| No approval | A publisher's page is visible to readers as soon as it is published, with no approval request. An urgent post by an urgent publisher alerts once, on publish |
| Unauthorised urgent | An urgent post by a publisher not on the urgent list sends nothing, logs *Skipped - not an urgent publisher* and tells Communications once |
| Unauthorised editor | An editor not on the list edits and republishes a page first created by an urgent publisher: nothing is sent |
| Partial address | An address that only partly matches a listed one (e.g. `chloe@` vs `chloe.l@`) sends nothing |
| Completion | UrgentSent becomes Yes only when every expected destination and channel reads back as *Sent* in the Delivery Log; rerun with only Reserved or Reconcile rows, or with the Delivery Log unreadable, leaves it No and alerts support |
| UrgentSent write | If setting UrgentSent fails or doesn't read back, support gets a high-importance email and nothing is resent |
| Audience-targeted urgent | Nothing is broadcast. A *Skipped - audience targeted* row is logged and Communications is emailed once |
| All ports | A post tagged *All ports* reaches every enabled row |
| Company-wide roundup | An enabled Comms Distribution row with Port All ports gets one digest listing every port's posts. An urgent post for All ports does **not** go to that row |
| Roundup by theme | `RoundupGroupByTheme` = Yes: posts appear under their theme headings (a post with two themes under both), posts with no theme under Other news |
| Roundup | Covers last Monday 00:00 to this Monday 00:00 UK time, for the right ports. A port with no posts gets nothing. A re-run later in the week sends nothing new |
| Roundup across the Monday boundary | Week A: make one destination fail (e.g. a Teams channel the flow owner isn't in) so its row is *Failed*. After the next Monday's run (week B) has finished, fix the destination. (1) Resubmit week A's original run: its Current_week_key is A and only the failed row is sent, or it shows B and nothing is sent for A; record which. (2) Set `RoundupReplayWeek` to A's Monday and run C2: A's failed row is sent once, B's rows are not resent, and the support mailbox gets the replay reminder. (3) Run again with it still set: nothing is sent, the reminder repeats. (4) Set it to a Tuesday, a future Monday and a Monday 10 weeks back: each is ignored and reported, and only the run's own week is processed. Clear it |
| Daylight saving | Runs in the week the clocks change still fire at 06:00 and 07:00 UK time |
| Reader boundary | Someone outside the HPUK reader group can't open pages or attachments |
| Retention | Deleting a test page leaves a copy in the Preservation Hold library (after the policy has distributed) |
| Retention check | With an existing rule of the wrong duration, or a KeepAndDelete rule without `-DeleteAfterRetention`, the script reports the difference and changes nothing. A rejected location update stops the run. The check passes only when both sites are in the policy and Distribution is Success |
| Provisioning re-run | Run the script twice on a clean pair of sites: the second run reports no drift and changes nothing. On a site with a blank Status default, it reports the drift; with `-FixDrift` it sets Live. With an item given its own permissions in Delivery Log, `-RepairPermissions` keeps it and lists it |

### Replaying a roundup week

Each roundup row's key holds its week: `roundup|2026-11-23|Felixstowe#4|Email`
is the run of Monday 23 November (covering 16 to 22 November).

1. Fix whatever made the row fail, then set the row's Delivery status to
   *Failed* if it isn't already (a *Reconcile* or *Reserved* row only after
   the recipient confirms it didn't arrive).
2. Before the next Monday 07:00: resubmit the failed run from C2's run
   history. Open the new run's **Current_week_key** step: if it shows the failed
   week, it is replaying that week and you are done.
3. Otherwise (after the next Monday, or if Current_week_key shows a later
   week): set the `RoundupReplayWeek` environment variable to the week in
   the key (`2026-11-23`) and run C2 (**Run** on the flow). It processes that
   week, where only the *Failed* rows send, and then its own week, where
   rows already *Sent* are skipped. The support mailbox gets a reminder.
   The value must be a Monday, before the run's own week and no more than 8
   weeks back; anything else is ignored and reported, and only the run's own
   week is processed.
4. Check the row is now *Sent*, then **clear** `RoundupReplayWeek`. Until it
   is cleared every run re-checks that week (nothing more is sent) and emails
   the reminder.

## Upgrading from 1.3.x or earlier

The dispatch keys change from `port` to `port#ID`, so rows logged by 1.3.x
aren't matched by 1.4.0.0 and later. Import it when nothing is in flight: after
Monday's roundup has finished, with no urgent post waiting to be resent
(the **Needs checking** view empty and no Failed urgent rows), and don't
resubmit a run from before the upgrade. In the first retry test, open the claim action (*Reserve retry*) and check its `IF-MATCH` header shows a version such as `"3"`, not `"no-etag"`: if it says no-etag, the connector didn't return the row's ETag and every retry claim will fail safe (nothing sent) until that is fixed. Re-running a week's roundup after
the upgrade would send it again to ports already sent under the old keys.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| A write fails with **BadGateway (502)** and `x-ms-datasourceerror: True`; the raw output's inner message says **"Additions to this Web site have been blocked"** | The site is locked (*No additions* or *Read-only*), its storage is full, or a SAM policy or Microsoft 365 Archive has made it read-only. Reads still work, every write fails, and retrying doesn't help | A SharePoint admin checks `Get-SPOSite -Identity <site> \| Select LockState, StorageUsageCurrent, StorageQuota`, then `Set-SPOSite -Identity <site> -LockState Unlock` or raises the quota (Active sites → the site → Settings). Check why it was locked first, and check both news sites |
| A retry claim fails with **412 Precondition Failed** | Another run (or a person) changed the Delivery Log row after this run read it | Nothing was sent by this run. Open the row: if it's Sent, nothing to do; if Failed again, re-run |
| Any write fails with 502 | The connector wraps SharePoint's own error as 502 | Open the failed action → **Show raw outputs** and read `innerError.message`: it names SharePoint's real error |


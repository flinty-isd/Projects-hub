# C1 News expiry: one-page walkthrough

**What it does:** every day at **06:00 UK time** it takes news posts past
their Expiry Date out of sight. It sets Status to *Expired* and Show in News
to *No*, then **unpublishes** the page back to draft, so it leaves every news
feed and readers can't open the link. It never deletes anything.

## The steps, in order

| # | Step (name in the run) | What it does | If it goes wrong |
|---|---|---|---|
| 1 | `Today_UK`, `Sites` | Today's date in UK time, and the two sites with their own Expiry column names (`Expiry_x0020_Date` on HPUK News, `ExpiryDate` on Other News) | — |
| 2 | `For_each_site` → `Get_expired_pages` | Published pages (`PromotedState` 2) whose Expiry Date is **before today**. A blank Expiry Date is never expired. Reads up to 100,000 pages | `Record_site_read_failed`: that site is listed in the support email; the other site still runs |
| 3 | `For_each_expired_page` → `Read_file_state` | Checks the page now: published (Level 1), draft (2) or checked out (255). One page at a time | `Record_read_failed`: listed in the support email, the next page carries on |
| 4 | `Condition_already_done` | Already draft **and** Expired **and** Show in News No → nothing to do | Counted as *already unpublished* |
| 5 | `Condition_writes_enabled` | `ExpiryWritesEnabled` = **No** → changes nothing, adds the page to the dry-run list | — |
| 6 | `Condition_checked_out` | Someone has the page checked out → left alone | Listed as *checked out*; check it in and the next run deals with it |
| 7 | `Expire_page` | Sets Status Expired and Show in News No, without making a new version | Carries on to the read-back, which reports it |
| 8 | `Unpublish_page` | If still published, unpublishes it (back to draft, comment *ExpiredByC1*) | As above |
| 9 | `Read_back` → `Condition_confirmed` | Reads the page again. **Done only if** it is draft and Expired | `Record_failure` with SharePoint's reply; the page stays in the support email until fixed |
| 10 | Emails | *Some expired posts are still published* (to the support mailbox, if anything failed); *dry run: posts that would be unpublished* (if writes are off); *News expiry report* (to `ExpiryReportEmail`, only if set) | — |
| 11 | `Catch_run_failed` | Anything not handled above (a connection expired, a list renamed) | *Flow failed* email to the support mailbox with the run link and failed step |

## What a normal day looks like

- **Most days:** the run succeeds in seconds, finds nothing or only pages already done, and sends no email (unless an expiry report is set up).
- **A post expired yesterday:** one page goes through steps 7 to 9. The expiry report (if set) lists it under *unpublished*. The post is gone from the home page and hub news; a reader opening its link is refused, an editor sees the draft.
- **Writes off (testing):** a *dry run* email lists the pages it would unpublish. Nothing changes.

## When you get an email

| Email or message | Usual cause | What to do |
|---|---|---|
| *Additions to this Web site have been blocked* (502) | The site is locked, read-only or full | SharePoint admin: `Get-SPOSite <url> \| Select LockState, StorageUsageCurrent, StorageQuota`, then unlock or raise the quota. See README, Troubleshooting |
| *checked out* | An editor has the page open or checked out | Ask them to check it in; nothing else needed |
| A page that read back as *published* | Site Pages has no draft versions, or draft security lets readers see drafts | Library settings → Versioning: major and minor; draft item security: *Only users who can edit items*. Re-run C1 |
| *Flow failed* | Connection, permissions or a renamed column | Open the run link, find the red step, read its raw output |

## Checking it yourself

1. Run history: each page appears once inside `For_each_expired_page`; green `Condition_confirmed` means done.
2. On the site: the page is a draft (Site Pages → *Draft*), Status Expired, Show in News No.
3. As a reader (or a test account in the reader group): the link gives *access denied*.
4. Re-run C1: the same page now counts as *already unpublished* and nothing changes.

## Settings it uses

`HPUKNewsSiteUrl`, `OtherNewsSiteUrl`, `ExpiryWritesEnabled` (off until proven),
`SupportOwnerEmail` (the support mailbox), `CommsSenderMailbox` (sender),
`ExpiryReportEmail` (optional).

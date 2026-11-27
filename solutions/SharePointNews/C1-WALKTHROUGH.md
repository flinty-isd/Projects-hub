# C1 News expiry: one-page walkthrough

**What it does (1.8.0.0):** every day at **06:00 UK time** it moves news posts
past their Expiry Date to the **News archive**. It sets Status *Expired*, Show
in News *No* and turns the post into an ordinary page (no longer a news post),
still published. The post leaves every news feed, hub news, Viva and the
Monday roundup, and staff can still read it from the site's News archive page.
It never deletes anything.

## The steps, in order

| # | Step (name in the run) | What it does | If it goes wrong |
|---|---|---|---|
| 1 | `Today_UK`, `Sites` | Today's date in UK time, and the two sites with their own Expiry column names (`Expiry_x0020_Date` on HPUK News, `ExpiryDate` on Other News) | — |
| 2 | `For_each_site` → `Get_expired_pages` | **News posts** (`PromotedState` 2) whose Expiry Date is **before today**. A blank Expiry Date never expires. An archived post is no longer a news post, so it isn't found again. Reads up to 100,000 pages | `Record_site_read_failed`: listed in the support email; the other site still runs |
| 3 | `For_each_expired_page` → `Read_file_state` | Checks the page now: published (Level 1), draft (2) or checked out (255). One page at a time | `Record_read_failed`: listed, the next page carries on |
| 4 | `Condition_checked_out` | Someone has it checked out → left alone | Listed as *checked out*; check it in and the next run archives it |
| 5 | `Condition_left_hidden` | A draft: a post someone unpublished, or that C1 unpublished before 1.8.0.0 → left hidden, unless `ArchiveUnpublishedExpired` is Yes | Listed under *left hidden* in the report |
| 6 | `Condition_writes_enabled` | `ExpiryWritesEnabled` = **No** → changes nothing, adds the page to the dry-run list | — |
| 7 | `Check_out` | Checks the page out so it can be changed safely | Reported with SharePoint's message; nothing changed |
| 8 | `Update_fields` | Status Expired, Show in News No, PromotedState 0 (not a news post) | `Undo_check_out`: the page is left as it was, not checked out |
| 9 | `Check_in` | Checks it in as a published major version (comment *ArchivedByC1*) | `Undo_after_check_in_failed`, then reported |
| 10 | `Read_back` → `Condition_confirmed` | Reads the page again. **Done only if** published, Expired and not a news post | `Record_failure` with the page state and SharePoint's reply to each step |
| 11 | Emails | *Some expired posts are still in the news feeds* (support mailbox, if anything failed); *dry run: posts that would be archived* (if writes are off); *News expiry report* (to `ExpiryReportEmail`, only if set) | — |
| 12 | `Catch_run_failed` | Anything not handled above (a connection expired, a list renamed) | *Flow failed* email with the run link and failed step |

## What a normal day looks like

- **Most days:** the run succeeds in seconds, finds nothing and sends no email (unless an expiry report is set up).
- **A post expired yesterday:** one page goes through steps 7 to 10. The report lists it under *archived*. It is gone from the news feeds and shows on the News archive page, where readers can open it.
- **Writes off (testing):** a *dry run* email lists the pages it would archive. Nothing changes.

## When you get an email

| Email or message | Usual cause | What to do |
|---|---|---|
| *Additions to this Web site have been blocked* (502) | The site is locked, read-only or full | SharePoint admin: `Get-SPOSite <url> \| Select LockState, StorageUsageCurrent, StorageQuota`, then unlock or raise the quota (README, Troubleshooting) |
| *checked out* | An editor has the page | Ask them to check it in; the next run archives it |
| *Check out: Failed* with an access message | The flow owner can't edit Site Pages | Give the named news flow owner Edit on Site Pages |
| *left hidden* list in the report | Posts unpublished before 1.8.0.0, or by a person | Check none was unpublished on purpose, then run C1 once with `ArchiveUnpublishedExpired` = Yes and set it back to No |
| *Flow failed* | Connection, permissions or a renamed column | Open the run link, find the red step, read its raw output |

## Checking it yourself

1. Run history: each page appears once in `For_each_expired_page`; green `Condition_confirmed` means done.
2. On the site: Page details shows the post as a page, Status Expired, Show in News No; it is published.
3. As a reader: it isn't in the home-page news, and the News archive page lists it and opens it.
4. Re-run C1: the archived post isn't picked up again.

## Settings it uses

`HPUKNewsSiteUrl`, `OtherNewsSiteUrl`, `ExpiryWritesEnabled` (off until proven),
`ArchiveUnpublishedExpired` (one-off, default No), `SupportOwnerEmail` (the
support mailbox), `CommsSenderMailbox` (sender), `ExpiryReportEmail` (optional).

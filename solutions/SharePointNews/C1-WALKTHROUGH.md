# C1 News expiry: one-page walkthrough

**What it does:** every day at **06:00 UK time** it takes news posts past
their Expiry Date out of the news. In one update it **removes the page from
news** (it stops being a news post), sets Status to *Expired* and Show in News
to *No*. The page stays **published**, so links in old emails and Teams posts
still work. It never unpublishes or deletes anything.

## The steps, in order

| # | Step (name in the run) | What it does | If it goes wrong |
|---|---|---|---|
| 1 | `Today_UK`, `Sites` | Today's date in UK time, and the two sites with their own Expiry column names (`Expiry_x0020_Date` on HPUK News, `ExpiryDate` on Other News) | — |
| 2 | `For_each_site` → `Get_expired_pages` | News posts (`PromotedState` 2) whose Expiry Date is **before today**. A blank Expiry Date is never expired. Reads up to 100,000 pages | `Record_site_read_failed`: that site is listed in the support email; the other site still runs |
| 3 | `For_each_expired_page` → `Read_file_state` | Checks the page now: published (Level 1), draft (2) or checked out (255). One page at a time | `Record_read_failed`: listed in the support email, the next page carries on |
| 4 | `Condition_writes_enabled` | `ExpiryWritesEnabled` = **No** → changes nothing, adds the page to the dry-run list | — |
| 5 | `Condition_checked_out` | Someone has the page checked out → left alone | Listed as *checked out*; check it in and the next run deals with it |
| 6 | `Expire_page` | Removes it from news (`PromotedState` 0) and sets Status Expired and Show in News No, without making a new version or a draft | Carries on to the read-back, which reports it |
| 7 | `Read_back` → `Condition_confirmed` | Reads the page again. **Done only if** it is no longer news and Expired. If it is still a draft from an earlier version of C1, it is also listed as *Still a draft* | `Record_failure` with SharePoint's reply; the page stays in the support email until fixed |
| 8 | Emails | *Some expired posts are still in the news* (to the support mailbox, if anything failed); *dry run: posts that would be removed from news* (if writes are off); *News expiry report* (to `ExpiryReportEmail`, only if set) | — |
| 9 | `Catch_run_failed` | Anything not handled above (a connection expired, a list renamed) | *Flow failed* email to the support mailbox with the run link and failed step |

## What a normal day looks like

- **Most days:** the run succeeds in seconds, finds nothing, and sends no email (unless an expiry report is set up).
- **A post expired yesterday:** one page goes through steps 6 and 7. The expiry report (if set) lists it under *Removed from news*. Within a few hours (search has to catch up) the post is gone from the home page, hub news and the SharePoint start page. Its link still opens it.
- **Writes off (testing):** a *dry run* email lists the pages it would remove from news. Nothing changes.

## When you get an email

| Email or message | Usual cause | What to do |
|---|---|---|
| *Additions to this Web site have been blocked* (502) | The site is locked, read-only or full Follow [runbooks/Site-Write-Failure.md](runbooks/Site-Write-Failure.md): check storage and lock state, unlock (after asking why it was locked) or raise the quota, then rerun |
| *checked out* | An editor has the page open or checked out | Ask them to check it in; nothing else needed |
| A page that read back with *news flag 2* | SharePoint accepted the call but didn't change the news flag (for example the page is open in edit) | Check the page isn't being edited, then re-run C1. If it repeats, demote it by hand (Site Pages → select the page → *Remove from news*, or open it and use *Page details*) |
| *Flow failed* | Connection, permissions or a renamed column | Open the run link, find the red step, read its raw output |

## Checking it yourself

1. Run history: each page appears once inside `For_each_expired_page`; green `Condition_confirmed` means done.
2. On the site: the page is still published, but Site Pages no longer lists it as news (add the *Promoted State* column to a view: it reads 0), Status Expired, Show in News No.
3. As a reader (or a test account in the reader group): the link still opens the page, and after a few hours it's no longer in the news web parts.
4. Re-run C1: the page is no longer news, so it isn't picked up and nothing changes.

## Settings it uses

`HPUKNewsSiteUrl`, `OtherNewsSiteUrl`, `ExpiryWritesEnabled` (off until proven),
`SupportOwnerEmail` (the support mailbox), `CommsSenderMailbox` (sender),
`ExpiryReportEmail` (optional).

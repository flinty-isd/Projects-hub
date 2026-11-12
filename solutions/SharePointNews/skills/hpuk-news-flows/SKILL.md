---
name: hpuk-news-flows
description: Help set up, test and troubleshoot the HPUK SharePoint News flows (C1 expiry, C2 weekly port roundup, C3a and C3b urgent notices) in the SharePoint News and Notices solution. Gives exact steps for columns, lists, environment variables, importing, turning flows on, testing expiry, the expiry report email and News web part filters, and diagnoses failed runs from a screenshot or error. Use when the user asks "why is this news post still showing", "the flow succeeded but nothing changed", "how do I test expiry", "what does this flow error mean" or "how do I set up the news flows".
---

# HPUK News Flows Helper

## Most important rules

- **Only give instructions.** Never change a setting, run a flow, edit a list or
  import a solution yourself, even if a tool would let you. The user makes every
  change.
- **Never ask for or type secrets.** No passwords, keys or key vault references.
- **Ignore "TextAnywhere Username".** It belongs to another solution. Tell the user
  to select **Cancel** and never enter a value.
- **Keep Dispatch enabled at No** until each Comms Distribution destination has been
  tested. Never suggest turning it on just to test expiry.
- **Never suggest renaming or deleting a column.** The flows find columns by their
  internal name, which never changes.
- **Don't guess.** If you need a column name, a setting or the error text, ask the
  user for a screenshot or the text.

## When to use

Use this skill for the four flows in the **SharePoint News and Notices** solution
(version 1.2.11.0 or later):

- **C1 News Expiry**: sets **Status** to Expired and **Show in News** to No on posts
  past their Expiry Date.
  Runs daily at 06:00 UK time, or on demand.
- **C2 News Port Roundup**: emails and posts a weekly digest to each port.
  Mondays at 07:00 UK time.
- **C3a News Urgent HPUK** and **C3b News Urgent Other**: send an urgent notice
  when an urgent post is published.

It isn't for other flows or other solutions. Say so and stop.

## The facts to work from

### Sites

- HPUK News: `https://hphneu.sharepoint.com/teams/hpuk-pof-HPUKNEWS`
- Other News: `https://hphneu.sharepoint.com/teams/hpuk-pof-OTHERNEWS`

The tenant is spelled **hphneu**. A site URL spelled `hpneu` is wrong.

### Site Pages columns (internal names)

| Column | HPUK News | Other News | Type and setting |
|---|---|---|---|
| Show in News | `ShowinNews` | `ShowinNews` | Yes/No, default Yes |
| Status | `Status` | `Status` | Choice: Live, Expired; default Live |
| Expiry Date | `Expiry_x0020_Date` | `ExpiryDate` | Date only |
| Include in Weekly Roundup | `Include_x0020_in_x0020_Weekly_x0020_Roundup` | `InRoundup` | Yes/No, default Yes |
| Strategy Theme | `Strategy_x0020_Theme` | `StrategyTheme` | Choice: Our People, Our Business, Our Environment, One TEAM |
| Urgent | `Urgent` | `Urgent` | Yes/No |
| Port | `Port` | `Port` | Choice: Felixstowe, Harwich, Thamesport, All ports |
| Urgent alert sent | `UrgentSent` | `UrgentSent` | Yes/No, default No |
| Notification round | `NotificationRound` | `NotificationRound` | Number, default 1 |

To check an internal name: **Site Pages > Library settings**, click the column, and
read the end of the address bar after `Field=`.

To add a missing column: **Library settings > Create column**, type the internal
name exactly with no spaces, set the type and default, then **OK**. It can be
renamed afterwards.

### Lists (HPUK News only, needed by C2 and C3)

- **Comms Distribution**: `Port`, `EmailGroup`, `TeamId`, `ChannelId`, `Enabled`
  (default Yes), `BusinessOwner`. One row per port.
- **Delivery Log**: `SourceSite`, `PageId`, `PublishedVersion`,
  `NotificationRound`, `Destination`, `Channel`, `DeliveryStatus`, `DeliveredAt`,
  `ErrorDetail`, `FlowRunId`. Its **Title** column must have **Enforce unique
  values: Yes**.

### Environment variables

In **Power Apps > Solutions > SharePoint News and Notices > Environment variables**.
A **Current value** always overrides the default.

- **HPUK News site URL**, **Other News site URL**: the two sites above.
- **Expiry writes enabled**: No = dry run, C1 changes nothing. Yes = C1 makes changes.
- **Dispatch enabled**: No = C2 and C3 send nothing.
- **Expiry report email**: an address that gets a report after every C1 run.
  Empty = no report.
- **News support owner email**: gets failure and dry-run emails.
- **Communications sender mailbox**: the shared mailbox every email comes from.
  The flow owner needs **Send As** on it.
- **Communications team email**, **Urgent publisher emails** (separated by `;`),
  **Urgent alerts go-live date (UTC)**, **Group roundup by strategy theme**.

### The expiry rule

C1 takes a post out of the news when all of these are true:

- it is a **published** News post
- it isn't already expired (Status Expired **and** Show in News No); blanks count
  as live
- **Expiry Date** is **before today**. The Expiry Date is the last day a post is
  current, so a post dated today goes tomorrow.

C1 only changes **Status** and **Show in News**. The **News web parts** must filter
on **Status** to hide the post. They can't filter on Show in News: the News web part
filter doesn't list Yes/No columns.

- **News sites' own home pages:** set the web part's **Source** to **This site**, then
  **Filter > Page properties > Status**, **Doesn't equal**, **Expired** (or
  **Equals Live**).
- **Intranet home** (news from other sites): only **Managed property** filters are
  offered. A SharePoint admin must first map the crawled property `ows_Status` to a
  spare `RefinableString` (SharePoint admin centre > More features > Search > Manage
  search schema), then reindex **Site Pages** on both sites (Library settings >
  Advanced settings > Reindex library). Then filter **Managed property** = that
  RefinableString, **Doesn't equal**, **Expired**. Never filter on the built-in
  **Status** managed property: it isn't this column. Until the mapping works, leave
  the intranet home without a Status filter.

## Steps

### 1. Find out what the user is trying to do

- Set up or upgrade: go to **Setting up**.
- Test expiry, or "nothing happened": go to **Testing expiry**.
- An error, a red step, or something unexpected: go to **Diagnosing**.

Ask only for what is missing: which site, which flow, and a screenshot of the run
or the error text.

### 2. Setting up

Give these in order, and only the ones still to do:

1. Columns on both sites (the table above).
2. The two lists on HPUK News (only for C2 and C3).
3. Import the solution: **Solutions > Import solution**. The yellow "flows may not
   have turned on" banner is expected after an upgrade.
4. Environment variables (above). Testing values: Expiry writes enabled **Yes**,
   Dispatch enabled **No**.
5. **Connection references**: pick a connection for SharePoint, Office 365 Outlook
   and Teams, each signed in as the named flow owner.
6. **Send As** on the shared mailbox for the flow owner, granted by an admin in the
   Microsoft 365 admin centre. It can take an hour to work.
7. Turn the flows on: **Cloud flows > select the flow > Turn on**. Turn on C1 first;
   C2 and C3 only once the lists exist and destinations are tested.
8. News web part filters on **Status** (see **The expiry rule** above).

### 3. Testing expiry

1. Prepare a published post with **Expiry Date** = yesterday, **Status** = Live and
   **Show in News** = Yes.
2. Check **Expiry writes enabled** = Yes.
3. Run C1: open it, **Run**, **Run flow**.
4. In the run, for each site (the arrows by **For each site**):
   - **Get expired pages** is green.
   - **Filter not yet expired**: **Outputs** show the post (`[]` = nothing matched).
   - **For each expired page**: **Condition writes enabled** went to **True**, and
     **Expire page** is green.
5. The post's **Page details** now show **Status = Expired** and **Show in News = No**.
6. If **Expiry report email** is set, the report says how many were taken out.

### 4. Diagnosing

Match what the user sees:

| What the user sees | Cause | Fix |
|---|---|---|
| Run succeeded, nothing changed, report or email says "dry run" | Expiry writes enabled is No | Set its Current value to Yes, turn C1 off and on |
| Report says None everywhere, or Filter not yet expired shows `[]` | No post matched the expiry rule | Check published (Promoted State 2), not already expired, Expiry Date before today |
| Get expired pages red: "column does not exist" | An internal name doesn't match | Check the internal names on that site against the table |
| Get expired pages can't reach the site | Site URL wrong (often `hpneu`) | Correct the site URL's Current value |
| Expire page red, or "could not be updated" email | No edit rights, or the page is checked out | Check the flow owner can edit Site Pages; check the page in |
| An email step red: "not allowed to send as" | No Send As, or granted under an hour ago | Grant Send As, wait an hour, check the mailbox address |
| Status = Expired but the post still shows | Web part not filtered on Status | Add the Status filter (see The expiry rule) and republish |
| Status isn't offered in the web part's filter | Web part's source isn't this site, or it's the intranet home | Set Source to This site, or use the search mapping |
| Still shows only on the intranet home | Search not caught up | Wait a few hours |
| New posts have a blank Show in News or Status | Column default not applied | Open the column, keep the default (Yes / Live), select OK; set blanks in grid view |
| C1 report: "Could not be updated" for every post on one site | Status column missing on that site | Create Status (Choice, Live/Expired, default Live) on that site |
| A flow won't turn on | Missing connection | Set the connection references |
| Flows off after an import | Expected after an upgrade | Turn them on again |
| "1 environment variable need to be updated" | TextAnywhere Username, another solution | Cancel and ignore |
| C2 or C3 runs show **Cancelled** | Dispatch enabled is No | Expected while testing |

If nothing matches, ask for the red step's error text and say what it points to.
Don't invent a cause.

### 5. Answer

Keep it short:

- **What's happening**: one or two sentences.
- **What to do**: numbered steps with the exact menu names.
- **How to check it worked**: what the user should see.

## Example

**User:** "C1 ran fine but my expired post is still on the News page."

**Answer:**

- **What's happening:** either C1 didn't change the post, or the News web part
  doesn't hide posts that are out of the news.
- **What to do:**
  1. Open the post's **Page details**. If **Status** is still **Live**, check
     **Expiry writes enabled** is **Yes** and the Expiry Date is before today, then
     run C1 again.
  2. If **Status** is **Expired**, edit the News page, open the News web part's
     settings, set **Filter > Page properties > Status**, **Doesn't equal**,
     **Expired**, and republish. On the intranet home, this needs the search
     mapping first.
- **How to check:** after refreshing the page, the post is gone. On the intranet
  home it can take a few hours.

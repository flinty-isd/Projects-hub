# Runbook: news flows fail when writes are switched on

**Audience:** Service Desk, with a SharePoint Administrator for steps 3 and 4.
**Applies to:** the HPUK News and Other News sites and the news flows
(C1 Expiry, C3a/C3b Urgent notices).

## Symptoms

- C1 Expiry works as a dry run (`ExpiryWritesEnabled` = No) but fails as
  soon as writes are switched on.
- The failed action is **Expire page** (or *Update expiry metadata* in the
  tenant copy). Power Automate shows **502 BadGateway**, and retries don't
  help. A run can hang for 20 minutes or more before it gives up.
- Under **Show raw outputs**, the headers include `x-ms-datasourceerror: True`
  and `innerError` contains:

  > Additions to this Web site have been blocked. Please contact the
  > administrator to resolve this problem.

  with error code `-2130575258`.
- Publishers may also be unable to create or edit posts, and urgent notices
  may not send (the Delivery Log and the *UrgentSent* flag live on HPUK News).

## Cause

The flow is fine. **SharePoint is refusing every change to the site.**
Reading still works, which is why the dry run passes. It was seen on
`hpuk-pof-HPUKNEWS` in November 2026. SharePoint gives this message when one of
these is true:

| Cause | Where to check |
|---|---|
| The site has a **lock** set to *No additions* or *Read-only*. This is often left behind by a migration tool | PowerShell only (step 3) |
| The site's **storage limit** is full | Admin centre (step 2) |
| The site is **archived** (Microsoft 365 Archive) | Admin centre (step 2) |
| A **SharePoint Advanced Management policy** (inactive site or attestation) has made it read-only. See [SAM-POLICIES.md](../../SharePointGovernance/SAM-POLICIES.md) | Admin centre (step 2) |

## 1. Confirm it is this problem

1. In Power Automate, open the failed C1 run and click the failed
   **Expire page** action.
2. Click **Show raw outputs**. Search for `innerError`.
3. If the message is *Additions to this Web site have been blocked*, carry
   on with this runbook. Note the site in the `source` URL (HPUK News or
   Other News).
4. If it says something else (for example *Item does not exist*, *checked
   out* or *save conflict*), this runbook doesn't apply: raise it with the
   news flow owner.

## 2. Check the site in the SharePoint admin centre

1. Open the SharePoint admin centre
   (admin.microsoft.com → **Admin centers → SharePoint**).
2. Go to **Sites → Active sites** and search for the site alias
   (`hpuk-pof-HPUKNEWS` or `hpuk-pof-OTHERNEWS`). Click the site **name**
   to open its details panel.
3. Check these:

| Look at | Problem if | Fix here? |
|---|---|---|
| **Storage used** against the **storage limit** (General tab, or the Storage column) | It is at or near 100% | Yes, if tenant storage is set to *Manual*: **Settings** tab → **Storage limit** → **Edit**, and raise it. Otherwise free space (old versions, recycle bin) |
| **Archive status** (column in the site list, or a banner in the panel) | *Archived* | Yes: select the site → **Reactivate** |
| **Policies → Site lifecycle management** | A policy covers this site with a read-only action | Yes: take the site out of the policy's scope, or turn off its read-only action, then restore the site |
| **Lock state** | Not shown in the admin centre | No: go to step 3 |

If storage is fine, the site isn't archived and no policy covers it, it is
almost certainly a **site lock**.

## 3. Check and clear a site lock (SharePoint Administrator)

Changing the lock needs the SharePoint Administrator role and the
SharePoint Online Management Shell.

**Before you unlock, find out why it was locked.** Ask the migration team,
the SharePoint service owner and Governance. If it was locked on purpose
(for example until launch, or for a records hold), **leave it locked**, keep
`ExpiryWritesEnabled` at No, and log the ticket as waiting on that team.

Check the lock and storage:

```powershell
Connect-SPOService -Url https://hphneu-admin.sharepoint.com
Get-SPOSite -Identity https://hphneu.sharepoint.com/teams/hpuk-pof-HPUKNEWS |
    Select-Object Url, LockState, StorageUsageCurrent, StorageQuota
```

`LockState` should be **Unlock**. If it is `NoAdditions` or `ReadOnly`, and
the owner has agreed, clear it:

```powershell
Set-SPOSite -Identity https://hphneu.sharepoint.com/teams/hpuk-pof-HPUKNEWS -LockState Unlock
```

Run `Get-SPOSite` again to confirm it now reads **Unlock**. The change can
take a few minutes to apply.

If you use PnP PowerShell instead:
`Set-PnPTenantSite -Url <site url> -LockState Unlock`.

Do **not** use `-LockState NoAccess`: it blocks everyone from the site.

**Always check the other news site as well**, with the same `Get-SPOSite`
command for `https://hphneu.sharepoint.com/teams/hpuk-pof-OTHERNEWS`. Both
sites were migrated together.

## 4. Prove the site accepts changes

As a site owner, edit a test news post on the site (or a page's properties
in **Site Pages**) and save it. If it saves, the site is writable. Undo your
change.

## 5. Rerun the flow safely

C1 is safe to rerun. It only picks pages whose Expiry Date has passed and
that aren't already *Expired* with Show in News = No, so pages already done
are skipped and nothing is changed twice.

1. **Dry run first.** Leave `ExpiryWritesEnabled` at **No** (solution →
   **Environment variables**). Open **C1 News Expiry** → **Run**. Check the
   dry-run email from the Communications mailbox lists the pages you expect,
   and only those.
2. **Switch writes on.** Set `ExpiryWritesEnabled` to **Yes**. If you
   change its *Current value*, turn C1 off and on again so it picks up the
   new value.
3. **Run C1 manually** and watch it. It should finish in a few minutes.
4. **Check the result:**
   - The expiry report (sent to `ExpiryReportEmail`, if set) lists the pages
     under *Taken out of the news*, and *Could not be updated* says None.
   - On each page in **Site Pages**: Status = *Expired*, Show in News = No.
     The page version hasn't changed and no draft has appeared.
   - The posts no longer appear in the news web parts.
5. **If it still fails:** set `ExpiryWritesEnabled` back to **No**, open the
   failed action's raw outputs again and escalate to the news flow owner
   with the `innerError` message and the `source` URL.

While investigating, you can stop a failing run hanging for 20 minutes: on
the failing action, **Settings → Timeout** `PT2M`, **Retry policy** *Fixed
interval*, count 1, interval `PT30S`. Put it back to **Default** once the
site is fixed.

### Urgent notices (C3a/C3b)

If urgent notices were published while the site was locked, the reserve
step will have failed, so **nothing was sent** and *UrgentSent* stayed No.
Once the site is unlocked, and only if `DispatchEnabled` is Yes, open each
affected C3 run and **Resubmit** it. The Delivery Log stops anything being
sent twice. Check the **Needs checking** view afterwards for *Reconcile*
rows.

## Close the ticket

Record in the ticket:

- which site(s) were affected, and the cause (lock, storage, archive or
  policy)
- who agreed to the unlock, and why it had been locked
- the C1 run that succeeded afterwards

Failures from the news flows go to the Communications shared mailbox. If the
same site locks again, raise it with the SharePoint service owner, as a
policy or migration job is probably reapplying it.

"""Write the HTML pages in pages/ that are uploaded to the PMO site's Site Pages library
(SharePoint HTML pages):

  PMO-Hub-Guide.html             for everyone: report a risk, ask for Board escalation,
                                 raise a change request, what happens next, what badges mean
  PMO-Governance-Reference.html  for the PMO and approvers: thresholds, tolerances,
                                 schedules, switches, recovery

SharePoint renders HTML pages in a sandboxed iframe with no data access, so these pages are
static: inline CSS, no JavaScript, no external fonts, images or scripts. The live panels stay
on Portfolio-Governance-Hub.aspx. Thresholds and tolerances come from solution-config.json,
and list names and URLs from sharepoint/list-schema.json, so the pages say what the flows do.

Links use the placeholder {SiteUrl}. Provision-PMOHub.ps1 -UploadHtmlPages replaces it with
the PMO site URL as it uploads the pages.

Usage:
  python solutions/EnterprisePMO/tools/build_pages.py           # rewrite pages/
  python solutions/EnterprisePMO/tools/build_pages.py --check   # fail if pages/ is out of date (CI)
"""
import json
import sys
from html import escape
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG = json.loads((ROOT / "solution-config.json").read_text())
SCHEMA = json.loads((ROOT / "sharepoint" / "list-schema.json").read_text())
OUT = ROOT / "pages"

# Where links open. "_top" leaves the HTML page's iframe and opens the target in the same tab.
# If a tenant's sandbox blocks top navigation (DEPLOY-AND-TEST T27), change to "_blank".
LINK_TARGET = "_top"


def d(name):
    return CONFIG["environmentVariables"][name]["default"]


def url(list_title, suffix=""):
    lst = next(l for l in SCHEMA["lists"] if l["listTitle"] == list_title)
    return "{SiteUrl}/" + lst["url"] + suffix


def choices(list_title, column):
    lst = next(l for l in SCHEMA["lists"] if l["listTitle"] == list_title)
    return next(f for f in lst["fields"] if f["internalName"] == column)["choices"]


def a(href, text):
    return f'<a href="{href}" target="{LINK_TARGET}">{text}</a>'


HUB = "{SiteUrl}/SitePages/Portfolio-Governance-Hub.aspx"
GUIDE = "{SiteUrl}/SitePages/PMO-Hub-Guide.html"
REFERENCE = "{SiteUrl}/SitePages/PMO-Governance-Reference.html"

CSS = """
:root {
  --bg: #f7f8fa; --surface: #ffffff; --text: #1f2933; --muted: #52606d; --line: #d9dee5;
  --accent: #1d4f91; --accent-soft: #e6eef9;
  --red-bg: #fee2e2; --red-fg: #7f1d1d; --red-line: #b91c1c;
  --amber-bg: #fef3c7; --amber-fg: #78350f; --amber-line: #b45309;
  --green-bg: #dcfce7; --green-fg: #14532d; --green-line: #15803d;
  --grey-bg: #f3f4f6; --grey-fg: #374151; --grey-line: #9ca3af;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #111418; --surface: #1a1f26; --text: #e6e9ee; --muted: #a3acb9; --line: #2e3640;
    --accent: #8db8f2; --accent-soft: #1c2a3d;
    --red-bg: #3b1214; --red-fg: #fecaca; --red-line: #f87171;
    --amber-bg: #3a2a0c; --amber-fg: #fde68a; --amber-line: #f59e0b;
    --green-bg: #0f2e1b; --green-fg: #bbf7d0; --green-line: #4ade80;
    --grey-bg: #262c34; --grey-fg: #d1d5db; --grey-line: #6b7280;
  }
}
* { box-sizing: border-box; }
html { -webkit-text-size-adjust: 100%; }
body { margin: 0; background: var(--bg); color: var(--text);
  font: 16px/1.55 "Segoe UI", system-ui, -apple-system, Roboto, "Helvetica Neue", Arial, sans-serif; }
.wrap { max-width: 980px; margin: 0 auto; padding: 24px 16px 48px; }
header.hero { background: var(--surface); border: 1px solid var(--line); border-radius: 12px; padding: 24px; }
.eyebrow { margin: 0 0 4px; color: var(--accent); font-size: 13px; font-weight: 600; letter-spacing: .06em; text-transform: uppercase; }
h1 { margin: 0 0 8px; font-size: 28px; line-height: 1.2; }
h2 { margin: 40px 0 12px; font-size: 22px; line-height: 1.25; }
h3 { margin: 24px 0 8px; font-size: 17px; }
p { margin: 0 0 12px; }
.lede { color: var(--muted); font-size: 17px; margin: 0; }
a { color: var(--accent); text-underline-offset: 2px; }
a:focus-visible, summary:focus-visible { outline: 3px solid var(--accent); outline-offset: 2px; border-radius: 4px; }
nav.toc { margin: 16px 0 0; display: flex; flex-wrap: wrap; gap: 8px; }
nav.toc a { display: inline-block; padding: 4px 10px; border: 1px solid var(--line); border-radius: 999px; text-decoration: none; font-size: 14px; background: var(--bg); }
.cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 12px; margin: 20px 0 0; }
.card { display: block; background: var(--surface); border: 1px solid var(--line); border-radius: 10px; padding: 16px; text-decoration: none; color: var(--text); }
.card strong { display: block; color: var(--accent); font-size: 16px; margin-bottom: 4px; }
.card span { color: var(--muted); font-size: 14px; }
.card:hover { border-color: var(--accent); }
section.panel { background: var(--surface); border: 1px solid var(--line); border-radius: 12px; padding: 4px 24px 20px; margin-top: 16px; }
ol.steps { list-style: none; counter-reset: s; padding: 0; margin: 12px 0; }
ol.steps > li { counter-increment: s; position: relative; padding: 0 0 14px 44px; }
ol.steps > li::before { content: counter(s); position: absolute; left: 0; top: 0; width: 30px; height: 30px; border-radius: 50%;
  background: var(--accent-soft); color: var(--accent); font-weight: 700; display: flex; align-items: center; justify-content: center; }
.flow { display: flex; flex-wrap: wrap; align-items: stretch; gap: 8px; margin: 12px 0 16px; padding: 0; list-style: none; }
.flow li { flex: 1 1 150px; background: var(--bg); border: 1px solid var(--line); border-radius: 8px; padding: 10px 12px; font-size: 14px; }
.flow li b { display: block; font-size: 13px; color: var(--muted); font-weight: 600; }
.table-wrap { overflow-x: auto; margin: 8px 0 16px; }
table { border-collapse: collapse; width: 100%; font-size: 15px; }
th, td { text-align: left; vertical-align: top; padding: 8px 10px; border-bottom: 1px solid var(--line); }
th { font-size: 13px; color: var(--muted); font-weight: 600; text-transform: uppercase; letter-spacing: .04em; }
.pill { display: inline-flex; align-items: center; gap: 6px; padding: 2px 10px; border-radius: 12px; font-size: 12px; font-weight: 600;
  letter-spacing: .04em; text-transform: uppercase; border: 1px solid; white-space: nowrap; }
.pill::before { content: ""; width: 7px; height: 7px; border-radius: 50%; background: currentColor; }
.badge { display: inline-block; padding: 2px 8px; border-radius: 6px; font-size: 13px; font-weight: 600; border: 1px solid; white-space: nowrap; }
.red { background: var(--red-bg); color: var(--red-fg); border-color: var(--red-line); }
.amber { background: var(--amber-bg); color: var(--amber-fg); border-color: var(--amber-line); }
.green { background: var(--green-bg); color: var(--green-fg); border-color: var(--green-line); }
.grey { background: var(--grey-bg); color: var(--grey-fg); border-color: var(--grey-line); }
.note { border-left: 4px solid var(--accent); background: var(--accent-soft); padding: 12px 16px; border-radius: 0 8px 8px 0; margin: 12px 0; }
details { border: 1px solid var(--line); border-radius: 8px; padding: 0 14px; margin: 8px 0; background: var(--bg); }
summary { cursor: pointer; padding: 10px 0; font-weight: 600; }
details[open] summary { border-bottom: 1px solid var(--line); margin-bottom: 10px; }
code { font-family: Consolas, "Cascadia Mono", Menlo, monospace; font-size: 14px; background: var(--bg); border: 1px solid var(--line); border-radius: 4px; padding: 0 4px; }
footer { margin-top: 40px; color: var(--muted); font-size: 14px; }
@media (max-width: 600px) {
  h1 { font-size: 24px; } h2 { font-size: 20px; }
  header.hero, section.panel { padding-left: 16px; padding-right: 16px; }
  th, td { padding: 6px 8px; }
}
@media print { body { background: #fff; } .cards, nav.toc { display: none; } section.panel, header.hero { border: 0; } }
""".strip()


def page(title, description, body):
    return f"""<!doctype html>
<html lang="en-GB">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="{escape(description)}">
<title>{escape(title)}</title>
<!-- Generated by tools/build_pages.py. Don't edit by hand: change the script and re-run it.
     Static HTML page for SharePoint Site Pages: inline CSS only, no scripts, no external files. -->
<style>
{CSS}
</style>
</head>
<body>
<div class="wrap">
{body}
<footer><p>Enterprise PMO Governance Hub {CONFIG['version']}. Generated from the solution's configuration, so the
timings and thresholds here are the ones the flows use. If the PMO changes a threshold, this page is regenerated.</p></footer>
</div>
</body>
</html>
"""


def rag_table():
    return """<div class="table-wrap"><table>
<tr><th>Rating</th><th>Use it when</th></tr>
<tr><td><span class="pill red">Red</span></td><td>A milestone, the budget or a benefit will be missed unless someone outside the workstream acts. Needs a decision or help now.</td></tr>
<tr><td><span class="pill amber">Amber</span></td><td>At risk, but the workstream has a credible plan to recover within its own authority. Watch closely.</td></tr>
<tr><td><span class="pill green">Green</span></td><td>On track, or the risk is fully mitigated.</td></tr>
<tr><td><span class="pill grey">Unassigned</span></td><td>Not rated yet. Rate every open item; unrated items can't be prioritised.</td></tr>
</table></div>"""


def guide():
    raid_types = ", ".join(choices("Master RAID Log", "RAIDType"))
    cr_types = ", ".join(choices("Change Requests", "ChangeType"))
    tol_gbp = f"£{d('CRBudgetTolerance'):,}"
    tol_days = d("CRScheduleToleranceDays")
    churn, window = d("ChurnThreshold"), d("ChurnWindowDays")
    body = f"""
<header class="hero">
  <p class="eyebrow">Enterprise PMO</p>
  <h1>Using the PMO governance hub</h1>
  <p class="lede">How to report a risk or issue, ask for something to go to the Executive Board, and raise a change
  to the baseline. It also covers what happens next and what the colours on the hub mean.</p>
  <div class="cards">
    <a class="card" href="{url('Master RAID Log', '/NewForm.aspx')}" target="{LINK_TARGET}"><strong>Report a risk or issue</strong><span>Opens a new Master RAID Log item</span></a>
    <a class="card" href="{url('Change Requests', '/NewForm.aspx')}" target="{LINK_TARGET}"><strong>Raise a change request</strong><span>Scope, budget or timeline change to the baseline</span></a>
    <a class="card" href="{HUB}" target="{LINK_TARGET}"><strong>Open the PMO hub</strong><span>Escalations, decisions, calendar and documents</span></a>
    <a class="card" href="{url('PMO Governance Calendar')}" target="{LINK_TARGET}"><strong>Governance calendar</strong><span>Steering Committee dates and submission deadlines</span></a>
  </div>
  <nav class="toc" aria-label="On this page">
    <a href="#risk">Report a risk</a><a href="#escalate">Board escalation</a><a href="#change">Change requests</a>
    <a href="#dates">Moving a date</a><a href="#badges">Colours and badges</a><a href="#pmo">What the PMO sees</a><a href="#help">Help</a>
  </nav>
</header>

<section class="panel" id="risk">
<h2>Report a risk or issue</h2>
<p>A <strong>risk</strong> might happen; an <strong>issue</strong> is happening now. The Master RAID Log also holds
assumptions and dependencies ({escape(raid_types)}).</p>
<ol class="steps">
  <li>Select {a(url('Master RAID Log', '/NewForm.aspx'), 'Report a risk or issue')} (also on the hub's quick links).</li>
  <li>Give it a short, specific <strong>title</strong>: what could go wrong, or what has gone wrong.</li>
  <li>Choose the <strong>type</strong> and the <strong>workstream</strong>. In <strong>Description</strong>, say what is happening and the impact on time, cost, scope or benefits.</li>
  <li>Set the <strong>RAG rating</strong> (table below), the <strong>owner</strong> who will manage it, and a <strong>target resolution date</strong>.</li>
  <li>Write the <strong>mitigation / resolution plan</strong>: what will be done, by whom, by when.</li>
  <li>Save. It shows in the RAID log straight away and is part of the weekly early-warning check.</li>
</ol>
{rag_table()}
</section>

<section class="panel" id="escalate">
<h2>Ask for Executive Board escalation</h2>
<p>Escalate when the item needs a <strong>decision or help above the workstream's authority</strong>, for example
funding, resources from another area, a supplier problem or a change of scope. Board escalation isn't a way to
make an item look more urgent.</p>
<ol class="steps">
  <li>On the RAID item (new or existing), tick <strong>Request Executive Board escalation</strong>.</li>
  <li>Fill in <strong>Why it needs the Board</strong>: what the Board must decide or unblock, and by when.</li>
  <li>Save. The Head of PMO gets an approval request with the details.</li>
</ol>
<ul class="flow" aria-label="What happens next">
  <li><b>Within 5 minutes</b>Escalation status: <span class="badge amber">Requested</span></li>
  <li><b>Within 3 days</b>The Head of PMO approves or declines</li>
  <li><b>If approved</b><span class="badge green">Approved</span> The item is flagged, shows on the hub and goes to the Steering Committee channel</li>
  <li><b>If declined or no decision</b><span class="badge red">Declined</span> or <span class="badge red">Not decided</span> The tick is cleared; you can ask again</li>
</ul>
<p>You and the item's owner get an email with the outcome and any comments. Once escalated, the item appears in
the Steering Committee's daily digest if it passes its target date.</p>
</section>

<section class="panel" id="change">
<h2>Raise a change request</h2>
<p>Raise a change request (CR) to change the approved <strong>baseline</strong>: scope, budget or timeline
({escape(cr_types)}). Don't move baseline dates or budget until the CR is approved.</p>
<ol class="steps">
  <li>Select {a(url('Change Requests', '/NewForm.aspx'), 'Raise a change request')}.</li>
  <li>Describe the <strong>change requested</strong> and the <strong>justification</strong>, and choose the workstream and change type.</li>
  <li>Enter the <strong>budget impact</strong> (GBP; negative for a saving) and the <strong>schedule impact</strong> in days, and summarise the impact on the baseline.</li>
  <li>Leave the CR reference blank: it is given a number (CR-nnn) automatically.</li>
</ol>
<h3>Who decides</h3>
<div class="table-wrap"><table>
<tr><th>The change</th><th>Decided by</th><th>Time to decide</th></tr>
<tr><td>Budget impact up to {tol_gbp} either way, schedule impact up to {tol_days} days, and not a scope change</td><td>PMO</td><td>14 days</td></tr>
<tr><td>Any scope change, budget impact over {tol_gbp}, or schedule impact over {tol_days} days</td><td>PMO review, then the Steering Committee</td><td>14 days, then 21 days</td></tr>
</table></div>
<h3>What the status means</h3>
<div class="table-wrap"><table>
<tr><th>Status</th><th>Meaning</th></tr>
<tr><td><span class="badge amber">Under review - PMO</span></td><td>The PMO is checking it is complete and correct.</td></tr>
<tr><td><span class="badge amber">Under review - Steering Committee</span></td><td>The PMO supports it; it is with the Steering Committee.</td></tr>
<tr><td><span class="badge green">Approved</span></td><td>Approved. The PMO updates the baseline. The decision is logged in the Action and Decision Tracker.</td></tr>
<tr><td><span class="badge red">Rejected</span></td><td>Not approved. The baseline doesn't change.</td></tr>
<tr><td><span class="badge red">Returned to requester</span></td><td>The PMO needs more or different information. Raise it again as a new request.</td></tr>
<tr><td><span class="badge red">Decision overdue</span></td><td>No decision in time. The PMO takes it to the next Steering Committee and records the outcome.</td></tr>
<tr><td><span class="badge grey">Withdrawn</span></td><td>You withdrew it. Set Status to Withdrawn at any time before the decision.</td></tr>
</table></div>
</section>

<section class="panel" id="dates">
<h2>Moving a target or due date</h2>
<p>Every time a RAID target date or an action due date is <strong>moved later</strong>, the change is recorded:
the old and new dates, how far it moved and who moved it. The first date an item ever had is kept as its
<strong>original baseline date</strong>. Bringing a date forward isn't counted.</p>
<div class="note"><p><strong>Why it matters:</strong> an item pushed {churn} or more times in {window} days is a sign the
forecast isn't stable, and flags its workstream in the weekly early-warning check. When you move a date, say why
in the mitigation or outcome, and quote the CR reference if a change request approved it.</p></div>
</section>

<section class="panel" id="badges">
<h2>Colours and badges on the hub</h2>
<p>Every badge shows its meaning in words, so the colour is never the only signal.</p>
<div class="table-wrap"><table>
<tr><th>Badge</th><th>Where</th><th>Meaning</th></tr>
<tr><td><span class="pill red">Red</span> <span class="pill amber">Amber</span> <span class="pill green">Green</span></td><td>RAG rating, workstream RAGs</td><td>See the RAG table above</td></tr>
<tr><td><span class="badge red">12 Nov 2026 · overdue</span></td><td>Target / due dates</td><td>Open and past its date</td></tr>
<tr><td><span class="badge amber">28 Nov 2026 · due soon</span></td><td>Target / due dates</td><td>Open and due within 7 days</td></tr>
<tr><td><span class="badge grey">✓ 03 Nov 2026</span></td><td>Target / due dates</td><td>Closed or completed</td></tr>
</table></div>
</section>

<section class="panel" id="pmo">
<h2>What the PMO and the Board see</h2>
<details><summary>Daily overdue digest: weekdays at 07:00</summary>
<p>The Steering Committee channel gets one card listing Board-escalated RAID items past their target date and
Executive Board actions and decisions past their due date. Nothing is posted when nothing is overdue.</p></details>
<details><summary>Weekly early warning: Mondays at 06:00</summary>
<p>Each active workstream is checked for three warning signs: risks and issues opening faster than they close,
actions closing too slowly against what is due, and dates being pushed repeatedly. A workstream with
{d('EarlyWarningThreshold')} or more signs gets an advisory in the PMO Risk Advisory channel with the reasons.
Details are in the {a(REFERENCE, 'governance reference')}.</p></details>
<details><summary>Executive escalations and decisions on the hub</summary>
<p>The {a(HUB, 'hub')} shows open Board escalations, decisions the Executive Board owes, the next 30 days of
governance meetings, the latest PIDs and charters, change requests in progress and escalation requests waiting
for the Head of PMO.</p></details>
</section>

<section class="panel" id="help">
<h2>Help</h2>
<p>For anything about the RAID log, escalations or change requests, contact the PMO through the PMO shared
mailbox. The standard delivery framework, stage-gate guidance and templates are in
{a(url('Governance Framework and SOPs'), 'Governance Framework &amp; SOPs')}.</p>
</section>
"""
    return page("PMO Hub Guide", "How to report a risk, ask for Board escalation and raise a change request on the Enterprise PMO hub.", body)


def reference():
    rows = [
        ("RVEL-HIGH", "Net risk velocity", "Risks and issues opened minus closed in the last 7 days",
         f"&ge; {d('RiskVelocityThreshold')}", "RiskVelocityThreshold"),
        ("ABD-SLO", "Action burn-down", "Actions closed in 7 days &divide; (actions opened in 7 days + open actions due in the next 10 days)",
         f"&lt; {d('BurnDownThresholdPercent') / 100:.2f}, with at least {d('BurnDownMinActionsDue')} actions due",
         "BurnDownThresholdPercent, BurnDownMinActionsDue"),
        ("CHURN-CRIT", "Date churn", f"One item's date pushed later within the last {d('ChurnWindowDays')} days",
         f"&ge; {d('ChurnThreshold')} pushes on one item", "ChurnThreshold, ChurnWindowDays"),
    ]
    ind = "\n".join(f"<tr><td><span class=\"badge amber\">{c}</span></td><td>{n}</td><td>{how}</td><td>{t}</td><td><code>{v}</code></td></tr>"
                    for c, n, how, t, v in rows)
    switches = [("DigestEnabled", "01", "Daily overdue digest to the Steering Committee channel"),
                ("EarlyWarningEnabled", "02", "Advisory cards to the PMO Risk Advisory channel (snapshots are written either way)"),
                ("CRApprovalsEnabled", "04", "Change request approvals (off: requests stay Submitted)"),
                ("EscalationAlertsEnabled", "05", "Steering Committee card when an escalation is approved (the approval runs either way)")]
    sw = "\n".join(f"<tr><td><code>{n}</code></td><td>{f}</td><td>{w}</td><td>{'Yes' if d(n) else 'No'}</td></tr>" for n, f, w in switches)
    lists = "\n".join(
        f"<tr><td>{a(url(l['listTitle']), escape(l['listTitle']))}</td><td>{escape(l['listDescription'])}</td></tr>"
        for l in SCHEMA["lists"])
    body = f"""
<header class="hero">
  <p class="eyebrow">Enterprise PMO · for the PMO and approvers</p>
  <h1>PMO governance reference</h1>
  <p class="lede">The rules the hub's flows apply: change tolerances, escalation and approval times, the
  early-warning indicators, the schedules and switches, and what to do when something gets stuck.</p>
  <nav class="toc" aria-label="On this page">
    <a href="#approvals">Approvals</a><a href="#warning">Early warning</a><a href="#schedule">Schedules</a>
    <a href="#switches">Switches</a><a href="#lists">Lists</a><a href="#recovery">When something is stuck</a>
  </nav>
</header>

<section class="panel" id="approvals">
<h2>Approvals and tolerances</h2>
<div class="table-wrap"><table>
<tr><th>Decision</th><th>Approvers (setting)</th><th>Rule</th><th>Time limit</th></tr>
<tr><td>Change request, PMO review</td><td><code>CRPMOApproverEmails</code></td><td>Every request. Rejecting returns it to the requester.</td><td>14 days</td></tr>
<tr><td>Change request, Steering Committee</td><td><code>CRSteerCoApproverEmails</code></td><td>After PMO approval, when it is a scope change, budget impact over £{d('CRBudgetTolerance'):,} (<code>CRBudgetTolerance</code>) or schedule impact over {d('CRScheduleToleranceDays')} days (<code>CRScheduleToleranceDays</code>)</td><td>21 days</td></tr>
<tr><td>RAID Board escalation</td><td><code>EscalationApproverEmails</code></td><td>When someone ticks Request Executive Board escalation</td><td>3 days</td></tr>
</table></div>
<p>The first approver to respond decides. Approvals can be reassigned in Teams or the Approvals app. A request not
decided in time becomes <span class="badge red">Decision overdue</span> (change request) or
<span class="badge red">Not decided</span> (escalation), and the PMO mailbox is emailed.</p>
</section>

<section class="panel" id="warning">
<h2>Early-warning indicators</h2>
<p>Every Monday, flow 02 scores each active workstream one point per indicator. It posts an advisory when the
score reaches <strong>{d('EarlyWarningThreshold')}</strong> (<code>EarlyWarningThreshold</code>, out of 3). The
scores are kept in PMO Trend Snapshots for the Power BI trend report.</p>
<div class="table-wrap"><table>
<tr><th>Code</th><th>Indicator</th><th>How it is worked out</th><th>Scores when</th><th>Setting</th></tr>
{ind}
</table></div>
<div class="note"><p>Tune thresholds on real data before switching the cards on: run with
<code>EarlyWarningEnabled</code> = No for a few weeks and compare the snapshots with what the PMO already knows.</p></div>
</section>

<section class="panel" id="schedule">
<h2>Schedules</h2>
<div class="table-wrap"><table>
<tr><th>Flow</th><th>When</th><th>What</th></tr>
<tr><td>01 Daily digest</td><td>Weekdays 07:00 UK</td><td>Overdue Board escalations and Executive Board actions and decisions, up to {d('DigestMaxItems')} of each (<code>DigestMaxItems</code>), once a day</td></tr>
<tr><td>02 Early warning</td><td>Mondays 06:00 UK</td><td>One snapshot per active workstream per week; advisory cards at threshold</td></tr>
<tr><td>03a / 03b Churn trackers</td><td>Within 5 minutes of a change</td><td>Date pushes, original baseline, closed and completed dates</td></tr>
<tr><td>04 Change requests</td><td>Within 5 minutes of a new request</td><td>Reference, PMO review, Steering Committee decision</td></tr>
<tr><td>05 Escalation requests</td><td>Within 5 minutes of the tick</td><td>Head of PMO approval; flag and Steering Committee card</td></tr>
</table></div>
<p>"Overdue" means past the date in UK time: an item due today is never overdue today.</p>
</section>

<section class="panel" id="switches">
<h2>Switches</h2>
<p>Environment variables in the Power Automate solution (Solutions &gt; Enterprise PMO Governance Hub &gt;
Environment variables). To stop all posting at once, set the first two to No.</p>
<div class="table-wrap"><table>
<tr><th>Setting</th><th>Flow</th><th>Controls</th><th>Default</th></tr>
{sw}
</table></div>
</section>

<section class="panel" id="lists">
<h2>Lists</h2>
<div class="table-wrap"><table>
<tr><th>List</th><th>Purpose</th></tr>
{lists}
</table></div>
<p>PMO Trend Snapshots, PMO Date Push Log and PMO Digest History are the audit trail: read-only for everyone
except the flow owner.</p>
</section>

<section class="panel" id="recovery">
<h2>When something is stuck</h2>
<details><summary>The daily digest didn't arrive</summary>
<p>Check PMO Digest History for today. <span class="badge red">Failed</span>: fix the cause (usually the channel, or
the flow owner left the team), delete the row and resubmit the run. No row: check <code>DigestEnabled</code> and the
flow's run history.</p></details>
<details><summary>A change request is Decision overdue</summary>
<p>Take it to the next Steering Committee. Record the outcome by hand: Status, Decided by, Decision note, and a
Decision Made item in the Action and Decision Tracker.</p></details>
<details><summary>An escalation request is stuck in Requested</summary>
<p>Its run failed after claiming it. Set Escalation status back to Not requested; if the box is still ticked, the
next edit sends a new approval.</p></details>
<details><summary>A "Flow failed" email arrived</summary>
<p>Open the run from the link, find the failed step, fix the cause and resubmit. See Stopping and recovery in
DEPLOY-AND-TEST.md in the deployment kit.</p></details>
<p>For people, not rules: the {a(GUIDE, 'PMO hub guide')}.</p>
</section>
"""
    return page("PMO Governance Reference", "Tolerances, approval times, early-warning indicators, schedules and switches for the Enterprise PMO hub.", body)


PAGES = {"PMO-Hub-Guide.html": guide, "PMO-Governance-Reference.html": reference}


def main():
    stale = []
    for name, build in PAGES.items():
        text = build()
        path = OUT / name
        if "--check" in sys.argv:
            if not path.exists() or path.read_text() != text:
                stale.append(name)
            continue
        OUT.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        print(f"Wrote pages/{name} ({len(text.encode()) // 1024} KB)")
    if "--check" in sys.argv:
        if stale:
            sys.exit(f"pages out of date: {stale}: run python solutions/EnterprisePMO/tools/build_pages.py")
        print("pages: up to date")


if __name__ == "__main__":
    main()

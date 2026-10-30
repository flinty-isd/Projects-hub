"""Draw the end-to-end swimlane workflow diagrams as SVG.

Writes
  solutions/SharePointGovernance/diagrams/governance-workflow.svg
  solutions/SharePointNews/diagrams/news-workflow.svg

Hand-placed layouts (Mermaid can't draw swimlanes) in the Hutchison Ports
brand: navy headings, Sky Blue accents only (it fails contrast as text),
light #F7F8FA / #EEF2F7 grounds, #33415C body, Montserrat headings and
Arial body. Outcome colours are the ones in the process diagrams. The detailed per-flow logic stays in the
Mermaid process diagrams; these show who does what, end to end.

Usage: python solutions/SharePointGovernance/tools/draw_workflows.py
"""
from pathlib import Path
from xml.sax.saxutils import escape

REPO = Path(__file__).resolve().parents[3]

NAVY, SKY = "#002E6D", "#009BDE"
INK, MUTED, LINE, HAIR = "#33415C", "#56627a", "#33415C", "#d2d5db"   # MUTED: #33415C tinted, 5.5:1 on #EEF2F7
LANE_A, LANE_B, LABEL_BG, AUTO_BG = "#ffffff", "#F7F8FA", "#EEF2F7", "#EEF2F7"
OUTCOME = {
    "good": ("#dcfce7", "#15803d", "#14532d"),
    "bad": ("#fee2e2", "#b91c1c", "#7f1d1d"),
    "info": ("#e0f2fe", "#0369a1", "#0c4a6e"),
}
FONT = "Arial, Helvetica, sans-serif"
HEAD = "Montserrat, Arial, sans-serif"


def text(cx, cy, lines, size=14, weight=400, color=INK, anchor="middle", lh=1.25, head=False):
    lines = lines if isinstance(lines, list) else [lines]
    y0 = cy - (len(lines) - 1) * size * lh / 2 + size * 0.35
    spans = "".join(
        f'<tspan x="{cx}" dy="{0 if i == 0 else size * lh:.1f}">{escape(ln)}</tspan>' for i, ln in enumerate(lines))
    family = f' font-family="{HEAD}"' if head else ""
    return (f'<text x="{cx}" y="{y0:.1f}"{family} font-size="{size}" font-weight="{weight}" '
            f'fill="{color}" text-anchor="{anchor}">{spans}</text>')


class Node:
    def __init__(self, cx, cy, w, h):
        self.cx, self.cy, self.w, self.h = cx, cy, w, h

    @property
    def l(self): return (self.cx - self.w / 2, self.cy)
    @property
    def r(self): return (self.cx + self.w / 2, self.cy)
    @property
    def t(self): return (self.cx, self.cy - self.h / 2)
    @property
    def b(self): return (self.cx, self.cy + self.h / 2)

    def at(self, side, dx=0, dy=0):
        x, y = getattr(self, side)
        return (x + dx, y + dy)


class Diagram:
    def __init__(self, width, title, subtitle, lanes, sections, footnote, label_w=190):
        self.w, self.title, self.subtitle, self.footnote = width, title, subtitle, footnote
        self.label_w, self.top = label_w, 132
        self.lanes, y = [], self.top
        for name, sub, h in lanes:
            self.lanes.append((name, sub, y, h))
            y += h
        self.bottom, self.h = y, y + 100
        self.sections, self.nodes, self.edges = sections, [], []

    def y(self, lane, frac=0.5):
        _, _, top, h = self.lanes[lane]
        return top + h * frac

    # --- shapes -------------------------------------------------------------
    def step(self, cx, cy, lines, w=210):
        """A step a person does."""
        lines = lines if isinstance(lines, list) else [lines]
        h = 26 + 18 * len(lines)
        self.nodes.append(
            f'<rect x="{cx - w / 2}" y="{cy - h / 2}" width="{w}" height="{h}" rx="8" fill="#ffffff" stroke="{LINE}" stroke-width="1.25"/>'
            + text(cx, cy, lines))
        return Node(cx, cy, w, h)

    def auto(self, cx, cy, badge, lines, w=220):
        """An automated step, with its flow number as a badge."""
        lines = lines if isinstance(lines, list) else [lines]
        h = 44 + 18 * len(lines)
        x, y = cx - w / 2, cy - h / 2
        bw = 16 + 7.5 * len(badge)
        self.nodes.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="{AUTO_BG}" stroke="{LINE}" stroke-width="1.25"/>'
            f'<rect x="{x + 12}" y="{y + 11}" width="{bw}" height="20" rx="10" fill="{NAVY}"/>'
            + text(x + 12 + bw / 2, y + 21, badge, 12, 700, "#ffffff")
            + text(cx, cy + 11, lines))
        return Node(cx, cy, w, h)

    def pill(self, cx, cy, label, kind):
        fill, stroke, ink = OUTCOME[kind]
        w = len(label) * 7.4 + 26
        self.nodes.append(
            f'<rect x="{cx - w / 2:.1f}" y="{cy - 13}" width="{w:.1f}" height="26" rx="8" fill="{fill}" stroke="{stroke}"/>'
            + text(cx, cy, label, 13, 600, ink))
        return Node(cx, cy, w, 26)

    def store(self, cx, cy, lines, w=210):
        lines = lines if isinstance(lines, list) else [lines]
        h = 30 + 18 * len(lines)
        x, y, e = cx - w / 2, cy - h / 2, 7
        self.nodes.append(
            f'<path d="M{x},{y + e} a{w / 2},{e} 0 0 0 {w},0 a{w / 2},{e} 0 0 0 {-w},0 v{h - 2 * e} '
            f'a{w / 2},{e} 0 0 0 {w},0 v{-(h - 2 * e)}" fill="#ffffff" stroke="{LINE}" stroke-width="1.25"/>'
            + text(cx, cy + 5, lines))
        return Node(cx, cy, w, h)

    def edge(self, *pts, label=None, at=None, dashed=False, arrow=True):
        """Polyline through pts. label sits at `at` (x, y), else mid first segment."""
        d = "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts)
        dash = ' stroke-dasharray="5 4"' if dashed else ""
        mark = ' marker-end="url(#arrow)"' if arrow else ""
        s = f'<path d="{d}" fill="none" stroke="{LINE}" stroke-width="1.5"{dash}{mark}/>'
        if label:
            lx, ly = at or ((pts[0][0] + pts[1][0]) / 2, (pts[0][1] + pts[1][1]) / 2)
            w = len(label) * 6.8 + 12
            s += (f'<rect x="{lx - w / 2:.1f}" y="{ly - 10:.1f}" width="{w:.1f}" height="19" rx="4" fill="#ffffff"/>'
                  + text(lx, ly - 0.5, label, 12, 600, MUTED))
        self.edges.append(s)

    # --- frame --------------------------------------------------------------
    def svg(self):
        lw, top, w = self.label_w, self.top, self.w
        out = [
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{self.h}" viewBox="0 0 {w} {self.h}" font-family="{FONT}">',
            '<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" '
            f'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{LINE}"/></marker></defs>',
            f'<rect width="{w}" height="{self.h}" fill="#ffffff"/>',
            f'<rect x="0" y="0" width="{w}" height="6" fill="{NAVY}"/>',
            f'<rect x="0" y="6" width="{w}" height="3" fill="{SKY}"/>',
            text(32, 48, self.title, 26, 700, NAVY, "start", head=True),
            text(32, 76, self.subtitle, 15, 400, MUTED, "start"),
        ]
        for i, (name, sub, y, h) in enumerate(self.lanes):
            out.append(f'<rect x="{lw}" y="{y}" width="{w - lw - 24}" height="{h}" fill="{LANE_A if i % 2 == 0 else LANE_B}"/>')
            out.append(f'<rect x="24" y="{y}" width="{lw - 24}" height="{h}" fill="{LABEL_BG}"/>')
            out.append(f'<rect x="24" y="{y}" width="4" height="{h}" fill="{SKY}"/>')
            out.append(text(40, y + h / 2 - 8, name, 14, 700, NAVY, "start", head=True))
            out.append(text(40, y + h / 2 + 12, sub, 12.5, 400, MUTED, "start"))
            out.append(f'<line x1="24" y1="{y}" x2="{w - 24}" y2="{y}" stroke="{HAIR}"/>')
        out.append(f'<line x1="24" y1="{self.bottom}" x2="{w - 24}" y2="{self.bottom}" stroke="{HAIR}"/>')
        for x0, x1, label in self.sections:
            out.append(f'<rect x="{x0}" y="{top - 34}" width="{x1 - x0}" height="26" rx="6" fill="{NAVY}"/>')
            out.append(text((x0 + x1) / 2, top - 21, label, 12.5, 600, "#ffffff", head=True))
        for x0, _, _ in self.sections[1:]:
            out.append(f'<line x1="{x0 - 20}" y1="{top - 34}" x2="{x0 - 20}" y2="{self.bottom}" stroke="{HAIR}" stroke-dasharray="4 4"/>')
        out += self.edges + self.nodes
        out.append(self._legend())
        out.append(text(32, self.h - 20, self.footnote, 12.5, 400, MUTED, "start"))
        out.append("</svg>")
        return "\n".join(out)

    def _legend(self):
        y, x = self.bottom + 44, 32
        s = [text(x, y, "Key", 13, 700, NAVY, "start", head=True)]
        x += 44
        s.append(f'<rect x="{x}" y="{y - 12}" width="34" height="24" rx="6" fill="#ffffff" stroke="{LINE}"/>')
        s.append(text(x + 44, y, "A person does it", 13, 400, MUTED, "start"))
        x += 170
        s.append(f'<rect x="{x}" y="{y - 12}" width="34" height="24" rx="6" fill="{AUTO_BG}" stroke="{LINE}"/>')
        s.append(f'<rect x="{x + 5}" y="{y - 7}" width="16" height="14" rx="7" fill="{NAVY}"/>')
        s.append(text(x + 44, y, "Automated, with its flow number", 13, 400, MUTED, "start"))
        x += 250
        for kind, label in (("good", "Granted or done"), ("bad", "Blocked, rejected or needs action"),
                            ("info", "Closed with guidance or follow-up")):
            fill, stroke, _ = OUTCOME[kind]
            s.append(f'<rect x="{x}" y="{y - 11}" width="34" height="22" rx="6" fill="{fill}" stroke="{stroke}"/>')
            s.append(text(x + 44, y, label, 13, 400, MUTED, "start"))
            x += 64 + len(label) * 6.6
        s.append(f'<path d="M{x},{y - 6} a17,4 0 0 0 34,0 a17,4 0 0 0 -34,0 v14 a17,4 0 0 0 34,0 v-14" fill="#ffffff" stroke="{LINE}"/>')
        s.append(text(x + 44, y, "SharePoint list", 13, 400, MUTED, "start"))
        x += 150
        s.append(f'<line x1="{x}" y1="{y}" x2="{x + 34}" y2="{y}" stroke="{LINE}" stroke-width="1.5" stroke-dasharray="5 4"/>')
        s.append(text(x + 44, y, "Later, or on a schedule", 13, 400, MUTED, "start"))
        return "".join(s)


# --------------------------------------------------------------------------
def governance():
    d = Diagram(
        2380,
        "SharePoint governance: request to review",
        "Business-as-usual controls from SharePoint Migration PID v4.2, enforced by Power Automate flows 01, 02, 03 and 06",
        [("Requester", "staff, site owner, sponsor", 150),
         ("Governance flows", "Power Automate", 210),
         ("Approvers", "owners, managers, InfoSec", 170),
         ("IT Operations", "and Service Desk", 140),
         ("Registers", "governance site lists", 150)],
        [(220, 1170, "Access to a site  ·  flow 01"),
         (1210, 1960, "A new site  ·  flow 03"),
         (2000, 2356, "Ongoing review  ·  flows 06 and 02")],
        "Flow 05 (file share disposition) runs separately on the File Share Register. "
        "Each flow's detailed decisions: diagrams/governance-flows.md.",
    )
    y = d.y

    # Access to a site: request, checks, approval, grant
    req = d.step(340, y(0), ["Raise an access request", "site, user type, justification"])
    chk = d.auto(340, y(1, 0.45), "01", ["Checks user type, licence,", "Entra ID P2, end date"], w=230)
    p1 = d.pill(640, y(1, 0.2), "Closed - Use Employee App", "info")
    p2 = d.pill(640, y(1, 0.45), "Blocked - Licence required", "bad")
    p3 = d.pill(640, y(1, 0.7), "Rejected - Prohibited", "bad")
    apr = d.step(640, y(2, 0.38), ["Approve or reject,", "by user type"], w=200)
    rej = d.pill(640, y(2, 0.82), "Rejected + comments", "bad")
    grant = d.auto(950, y(1, 0.45), "01", ["Grants through a", "security group"], w=200)
    granted = d.pill(1110, y(1, 0.45), "Granted", "good")
    it1 = d.step(950, y(3), ["Service Desk: AD group change", "IT Ops: PIM eligible assignment"], w=250)
    reg1 = d.store(950, y(4), ["Access Requests", "Guest Access Register"], w=220)

    d.edge(req.b, chk.t)
    trunk = chk.r[0] + 30
    d.edge(chk.r, (trunk, chk.cy), arrow=False)
    for p in (p1, p2, p3):
        d.edge((trunk, chk.cy), (trunk, p.cy), p.l)
    d.edge(chk.r, (trunk, chk.cy), label="fails a rule", at=(trunk, y(1, 0.84)), arrow=False)
    d.edge(chk.b, (chk.cx, apr.cy), apr.l, label="passes", at=(chk.cx, y(2, 0.1)))
    d.edge(apr.b, rej.t, label="No", at=(apr.cx + 20, (apr.b[1] + rej.t[1]) / 2))
    d.edge(apr.r, (900, apr.cy), grant.at("b", -50), label="Yes", at=(820, apr.cy))
    d.edge(grant.r, granted.l)
    d.edge(grant.at("b", 50), it1.at("t", 50), label="synced group or admin", at=(1000, y(2, 0.62)))
    d.edge(it1.b, reg1.t, label="recorded", dashed=True)

    # A new site: request, checks, approval, create, grant, register
    req2 = d.step(1340, y(0), ["Raise a site request", "alias, two owners, groups"])
    chk2 = d.auto(1340, y(1, 0.45), "03", ["Checks naming standard,", "two named owners, groups"], w=230)
    q1 = d.pill(1600, y(1, 0.3), "Returned - Naming standard", "bad")
    q2 = d.pill(1600, y(1, 0.6), "Returned - Ownership invalid", "bad")
    apr2 = d.step(1600, y(2, 0.38), ["Service owner approves;", "InfoSec too if external sharing", "or Highly Confidential"], w=240)
    rej2 = d.pill(1600, y(2, 0.86), "Rejected", "bad")
    make = d.auto(1855, y(1, 0.45), "03", ["Creates the site, then", "applies the baseline"], w=190)
    done = d.pill(1855, y(0), "Provisioned - owners told", "good")
    it2 = d.step(1855, y(3), ["IT Ops applies and", "registers Sites.Selected"], w=190)
    reg2 = d.store(1855, y(4), ["Site Register", "first review in 90 days"], w=190)

    d.edge(req2.b, chk2.t)
    trunk2 = chk2.r[0] + 25
    d.edge(chk2.r, (trunk2, chk2.cy), label="fails", at=(trunk2, y(1, 0.75)), arrow=False)
    for q in (q1, q2):
        d.edge((trunk2, chk2.cy), (trunk2, q.cy), q.l)
    d.edge(chk2.b, (chk2.cx, apr2.cy), apr2.l, label="passes", at=(chk2.cx, y(2, 0.1)))
    d.edge(apr2.b, rej2.t, label="No", at=(apr2.cx + 20, (apr2.b[1] + rej2.t[1]) / 2))
    d.edge(apr2.r, (1805, apr2.cy), make.at("b", -50), label="Yes", at=(1760, apr2.cy))
    d.edge(make.at("b", 50), it2.at("t", 50), label="grant first", at=(1905, y(2, 0.62)))
    d.edge(make.t, done.b)
    d.edge(it2.b, reg2.t, label="baseline applied", at=(1855, (it2.b[1] + reg2.t[1]) / 2))

    # Ongoing review
    rev = d.auto(2085, y(1, 0.45), "06", ["Monthly, 1st, 07:00:", "sites due for review"], w=170)
    own = d.step(2085, y(0), ["Owner recertifies", "Owners and Members"], w=170)
    sd = d.step(2085, y(3), ["Service Desk", "removes access"], w=170)
    log = d.store(2085, y(4), ["Access Review Log", "next review +90 days"], w=170)
    gx = d.auto(2265, y(1, 0.45), "02", ["Daily 06:00:", "guests at end date"], w=160)
    spn = d.step(2265, y(0), ["Owner or sponsor", "confirms removal"], w=160)
    glog = d.store(2265, y(4), ["Guest Access", "Register"], w=160)

    gap = 1980
    d.edge(reg2.r, (gap, reg2.cy), (gap, rev.cy), rev.l, label="review due", at=(gap, y(2, 0.5)), dashed=True)
    d.edge(rev.t, own.b, label="email", at=(rev.cx, y(0, 0.95)))
    d.edge(rev.b, sd.t, label="removals", at=(rev.cx, y(2, 0.5)))
    d.edge(sd.b, log.t, label="logged", dashed=True)
    d.edge(gx.t, spn.b, label="ask", at=(gx.cx, y(0, 0.95)))
    d.edge(gx.b, glog.t, label="Expired or Kept", at=(gx.cx, y(2, 0.5)))
    d.edge(reg1.at("b"), (reg1.cx, y(4, 0.95)), (glog.cx, y(4, 0.95)), glog.b,
           label="guest end dates", at=(1560, y(4, 0.95)), dashed=True)
    return d.svg()


def news():
    d = Diagram(
        2000,
        "SharePoint News: publish to inbox",
        "SharePoint Online News Design v1.2: the HPUK News and Other News sites, automated by flows C1, C2 and C3a/C3b",
        [("Publisher", "trained, named publishers", 140),
         ("News sites", "Site Pages, intranet home", 150),
         ("News flows", "Power Automate", 200),
         ("Recipients", "port email groups, Teams", 120),
         ("Communications", "and support owner", 130),
         ("Delivery Log", "one row per send", 120)],
        [(220, 690, "Publish"),
         (730, 1270, "Urgent notice  ·  C3a / C3b, on publish"),
         (1310, 1610, "Weekly roundup  ·  C2"),
         (1650, 1976, "Expiry  ·  C1")],
        "Master switches DispatchEnabled and ExpiryWritesEnabled stay off until proven. "
        "Each flow's detailed decisions: diagrams/news-flows.md.",
    )
    y = d.y

    draft = d.step(330, y(0), ["Create post from template", "Port, Category, Expiry date, Urgent"], w=240)
    pub = d.step(590, y(0), ["Publish", "pre-approved, no page approval"], w=220)
    live = d.step(560, y(1, 0.5), ["Live on HPUK News or", "Other News and intranet home"], w=220)
    d.edge(draft.r, pub.l)
    d.edge(pub.at("b", -30), live.at("t", 0))

    # Urgent notice
    chk = d.auto(870, y(2, 0.42), "C3", ["Urgent checks: go-live date,", "urgent publisher, not targeted"], w=230)
    told = d.step(870, y(4), ["Told once:", "skipped urgent post"], w=180)
    send = d.auto(1140, y(2, 0.42), "C3", ["Reserve, then send", "per port and channel"], w=200)
    urg = d.step(1140, y(3), ["Urgent email and", "Teams channel post"], w=190)
    sent = d.pill(1060, y(1, 0.72), "UrgentSent = Yes", "good")
    d.edge(live.at("r", 0, 15), (720, live.cy + 15), (720, chk.cy), chk.l, label="Urgent, published", at=(720, y(2, 0.1)))
    d.edge(chk.b, told.t, label="fails a check", at=(chk.cx, y(3, 0.5)))
    d.edge(chk.r, send.l, label="passes", at=((chk.r[0] + send.l[0]) / 2, chk.cy - 14))
    d.edge(send.at("t", 40), (1180, sent.cy), sent.r, label="all sent", at=(1180, y(2, 0.04)))
    d.edge(send.b, urg.t)

    # Weekly roundup and expiry: scheduled reads of the live posts
    rnd = d.auto(1460, y(2, 0.42), "C2", ["Mondays 07:00: last week's", "Live posts, per port"], w=230)
    dig = d.step(1460, y(3), ["Weekly digest email", "and Teams post"], w=190)
    exp = d.auto(1810, y(2, 0.42), "C1", ["Daily 06:00: Live posts", "past their expiry date"], w=220)
    gone = d.pill(1810, y(1, 0.72), "Status = Expired", "info")
    bus = y(1, 0.3)
    d.edge(live.at("r", 0, -15), (700, live.cy - 15), (700, bus), (1680, bus), (1680, exp.cy), exp.l,
           label="Live posts, daily", at=(1680, y(2, 0.14)), dashed=True)
    d.edge((1460, bus), rnd.t, label="in roundup, weekly", at=(1460, y(1, 0.72)), dashed=True)
    d.edge(exp.at("t", 0), gone.b, label="drops off News", at=(exp.cx, y(1, 0.98)))
    d.edge(rnd.b, dig.t, label="reserve, then send", at=(rnd.cx, y(3, 0.0)))

    # Delivery Log and support
    dl = d.store(1300, y(5), ["Reserved → Sent / Failed / Reconcile"], w=330)
    sup = d.step(1810, y(4), ["Support owner: failures", "and Reconcile rows to check"], w=230)
    d.edge(urg.b, (1140, y(4, 0.7)), (1220, y(4, 0.7)), (1220, dl.t[1] - 2))
    d.edge(dig.b, (1460, y(4, 0.7)), (1380, y(4, 0.7)), (1380, dl.t[1] - 2))
    d.edge(dl.r, (sup.cx, dl.cy), sup.b, label="Failed or Reconcile", at=(1640, dl.cy))
    d.edge(exp.at("b", -50), sup.at("t", -50), label="failures", at=(1760, y(3, 0.5)), dashed=True)
    return d.svg()


def main():
    out = {
        REPO / "solutions/SharePointGovernance/diagrams/governance-workflow.svg": governance(),
        REPO / "solutions/SharePointNews/diagrams/news-workflow.svg": news(),
    }
    for path, svg in out.items():
        path.write_text(svg)
        print(f"wrote {path.relative_to(REPO)}")


if __name__ == "__main__":
    main()

# Hutchison Ports branding and pages for SharePoint Online

The Hutchison Ports brand applied natively to the governance site, plus the
site's pages and the end-to-end workflow diagram. It uses only built-in SharePoint features: a theme, column
formatting and modern pages with text web parts. There's no SPFx, custom
script or extra licence.

- **Theme:** the "Hutchison Ports" palette (`theme/hutchison-ports-theme.json`):
  navy `#002E6D` as the primary colour, body `#33415C`, light `#F7F8FA` /
  `#EEF2F7`. Sky Blue `#009BDE` is for accents only (it fails contrast as
  text), so it isn't a theme slot.
- **Status columns:** every Status column in the governance lists shows its
  value as a coloured box in the colours of
  [`../diagrams/governance-flows.md`](../diagrams/governance-flows.md): green
  for granted or approved, red for blocked, rejected or failed, blue for
  redirected or follow-up, grey for not decided yet. The words always stay
  visible, because the green and red differ by hue only.
- **Pages:** six pages from `pages/pages.json`: Governance overview, Request
  access, Request a site, Access reviews, File shares, and Roles.
  Each is linked to its lists and added to the left-hand navigation. The
  overview page shows the governance swimlane diagram
  (`pages/images/governance-workflow.png`, drawn by
  `tools/draw_workflows.py`) with an Image web part that opens it full size.

Choose one way to apply it.

## Option A: browser script (no install, about a minute)

Needs Site Owner on the governance site, plus a browser whose developer tools
your organisation allows.

1. Open the governance site: the **IT Enterprise Governance** site that holds
   the governance lists.
2. Press **F12** and open **Console**.
3. Paste all of [`browser/apply-governance-site.js`](browser/apply-governance-site.js)
   and press Enter. Chrome and Edge may ask you to type `allow pasting` first.
4. Check the table it prints: one row per step, `OK` or `FAILED` with the
   reason. Reload the page.

You can run it again safely. It replaces the theme, the column formatting and
the diagram in Site Assets, leaves existing pages alone, and doesn't duplicate
navigation links. If you already ran an earlier version, change
`const UPDATE_EXISTING = false;` near the top to `true` before pasting: it
rewrites the six pages from the script, so any edits made to them on the site
are lost.

## Option B: Copilot and the browser UI (no scripts)

1. **Theme.** A SharePoint Administrator opens **SharePoint admin centre →
   Brand center → Themes → Add theme**, names it *Hutchison Ports*, and enters
   `themePrimary` `#002E6D`. Then, on the governance site, a Site Owner picks
   it under **Settings → Change the look → Theme**. If Brand center isn't
   switched on for your tenant, use the closest built-in theme (Red) until it
   is.
2. **Status columns** (once per list). Open the list and choose **Status column
   header → Column settings → Format this column → Advanced mode**. Paste the
   matching file from [`column-formats/`](column-formats/) and **Save**.
3. **Pages.** Follow [`copilot/page-prompts.md`](copilot/page-prompts.md):
   one Copilot prompt per page, with the facts to check before publishing.

## Fonts and logo

The brand uses Montserrat for headings and Arial for body text. To use them on
the site, add a font package in Brand center (Montserrat is on Google Fonts
under the SIL Open Font License) and pick it under **Change the look → Font**.
Without it, SharePoint keeps Segoe UI.

Set the corporate mark as the site logo under **Change the look → Header →
Site logo**, using the supplied PNG. Place it on a light header only: there is
no reversed version for navy.

## Changing things

| To change | Edit | Then run |
|-----------|------|----------|
| A status's colour, or a new status | `status-map.json` | `tools/build_formatters.py`, then `tools/build_site_kit.py` |
| Page wording or a new page | `pages/pages.json` | `tools/build_site_kit.py` |
| Theme colours | `theme/hutchison-ports-theme.json` | `tools/build_site_kit.py` |
| A diagram | `tools/draw_workflows.py`, then re-export `pages/images/*.png` | `tools/build_site_kit.py` |

Never edit `column-formats/`, `browser/` or `copilot/` by hand: they're
generated. CI runs both tools with `--check`. It fails when a choice in
`../sharepoint/list-schema.json` has no colour, when a page uses HTML the text
web part drops or links a missing page or list, or when a generated file is
out of date.

`Set-GovernanceBranding.ps1` does the theme and column steps with
PnP.PowerShell, for later if PowerShell becomes available.

## Notes

- In text for staff, don't abbreviate the company name (brand V6). Site names
  such as *HPUK News* are the sites' own titles.
- The browser script calls SharePoint's REST API as the signed-in user. It
  can't do anything that user couldn't do by hand. It is about 680 KB because
  it carries the diagram.
- The Image web part settings it writes haven't been tried on a live tenant
  yet. If the diagram doesn't show, the caption's *Open the diagram full size*
  link still works, and you can add the image by hand from Site Assets.

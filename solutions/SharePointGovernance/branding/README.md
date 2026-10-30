# Projects Hub branding and pages for SharePoint Online

The Projects Hub design system applied natively to the governance site, plus
the site's pages. It uses only built-in SharePoint features: a theme, column
formatting and modern pages with text web parts. There's no SPFx, custom
script or extra licence.

- **Theme:** the "Projects Hub" palette (`theme/projects-hub-theme.json`).
- **Status columns:** every Status column in the governance lists shows its
  value as a coloured box in the colours of
  [`../diagrams/governance-flows.md`](../diagrams/governance-flows.md): green
  for granted or approved, red for blocked, rejected or failed, blue for
  redirected or follow-up, grey for not decided yet. The words always stay
  visible, because the green and red differ by hue only.
- **Pages:** six pages from `pages/pages.json`: Governance overview, Request
  access, Request a site, Access reviews, File shares, and Roles.
  Each is linked to its lists and added to the left-hand navigation.

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

You can run it again safely. It replaces the theme and the column formatting,
leaves existing pages alone, and doesn't duplicate navigation links. To
rebuild a page, delete it first.

## Option B: Copilot and the browser UI (no scripts)

1. **Theme.** A SharePoint Administrator opens **SharePoint admin centre →
   Brand center → Themes → Add theme**, names it *Projects Hub*, and enters
   `themePrimary` `#c73a3a`. Then, on the governance site, a Site Owner picks
   it under **Settings → Change the look → Theme**. If Brand center isn't
   switched on for your tenant, use the closest built-in theme (Red) until it
   is.
2. **Status columns** (once per list). Open the list and choose **Status column
   header → Column settings → Format this column → Advanced mode**. Paste the
   matching file from [`column-formats/`](column-formats/) and **Save**.
3. **Pages.** Follow [`copilot/page-prompts.md`](copilot/page-prompts.md):
   one Copilot prompt per page, with the facts to check before publishing.

## Font

Optionally, add Source Sans 3 (SIL Open Font License, from Google Fonts) as a
font package in Brand center and pick it under **Change the look → Font**.
Without it, SharePoint keeps Segoe UI.

## Changing things

| To change | Edit | Then run |
|-----------|------|----------|
| A status's colour, or a new status | `status-map.json` | `tools/build_formatters.py`, then `tools/build_site_kit.py` |
| Page wording or a new page | `pages/pages.json` | `tools/build_site_kit.py` |
| Theme colours | `theme/projects-hub-theme.json` | `tools/build_site_kit.py` |

Never edit `column-formats/`, `browser/` or `copilot/` by hand: they're
generated. CI runs both tools with `--check`. It fails when a choice in
`../sharepoint/list-schema.json` has no colour, when a page uses HTML the text
web part drops or links a missing page or list, or when a generated file is
out of date.

`Set-GovernanceBranding.ps1` does the theme and column steps with
PnP.PowerShell, for later if PowerShell becomes available.

## Notes

- `themePrimary` is `#c73a3a`, a darker shade of the design system's Streamlit
  red `#ff4b4b`. SharePoint puts white text on `themePrimary` and uses it for
  links, and `#ff4b4b` only reaches 3.3:1 there; `#c73a3a` reaches 5.1:1.
- The browser script calls SharePoint's REST API as the signed-in user. It
  can't do anything that user couldn't do by hand.

# Hutchison Ports branding and pages for the News sites

The same no-PowerShell kit as the governance site
([`../../SharePointGovernance/branding/`](../../SharePointGovernance/branding/README.md)),
for the HPUK News and Other News sites. It uses only built-in SharePoint features.

- **Theme:** the shared "Hutchison Ports" palette
  (`../../SharePointGovernance/branding/theme/hutchison-ports-theme.json`):
  navy `#002E6D` primary, body `#33415C`, light `#F7F8FA` / `#EEF2F7`.
- **Status columns:** *Status* on Site Pages and Notices and Attachments (Live
  green, Expired blue), and *DeliveryStatus* on the Delivery Log (Sent green;
  Failed and the skips that need Communications red; Reconcile and
  audience-targeted skips blue; Reserved grey). The colours match
  [`../diagrams/news-flows.md`](../diagrams/news-flows.md), and the words
  always stay visible.
- **Publisher Guide page:** the News swimlane diagram
  (`pages/images/news-workflow.png`) at the top, opening full size, then each
  section of [`../pages/Publisher-Guide.html`](../pages/Publisher-Guide.html)
  as its own text web part. That file stays the single source for the guide's
  wording.

## Option A: browser script

Needs Site Owner on the site. Run it once on **HPUK News** and once on
**Other News**, so both sites get the theme, the status colours and the guide.

1. Open the site and press **F12**, then open **Console**.
2. Paste all of [`browser/apply-news-site.js`](browser/apply-news-site.js) and
   press Enter. Chrome and Edge may ask you to type `allow pasting` first.
3. Check the table it prints (`OK` or `FAILED` for each step), then reload.

If `Provision-NewsSites.ps1` already created the Publisher Guide, the script
leaves it alone. To replace it with the version that has the diagram, change
`const UPDATE_EXISTING = false;` near the top to `true` before pasting. That
rewrites the page, so edits made on the site are lost.

The guide isn't added to the site navigation. Link it from the publishers'
Quick Links, as the design does.

## Option B: Copilot and the browser UI

1. **Theme:** as in the governance kit (Brand center, *Hutchison Ports*,
   `themePrimary` `#002E6D`).
2. **Status columns:** for each column, open its header and choose **Column
   settings → Format this column → Advanced mode**. Paste the matching file
   from [`column-formats/`](column-formats/).
3. **Publisher Guide:** follow [`copilot/page-prompts.md`](copilot/page-prompts.md).

## Changing things

| To change | Edit | Then run |
|-----------|------|----------|
| A status colour | `status-map.json` | `build_formatters.py --root solutions/SharePointNews`, then `build_site_kit.py --root solutions/SharePointNews` |
| The guide's wording | `../pages/Publisher-Guide.html` | `build_site_kit.py --root solutions/SharePointNews` |
| The diagram | `../../SharePointGovernance/tools/draw_workflows.py`, then re-export `pages/images/news-workflow.png` | `build_site_kit.py --root solutions/SharePointNews` |

Both tools are in `solutions/SharePointGovernance/tools/`. CI runs them with
`--check`. Never edit `column-formats/`, `browser/` or `copilot/` by hand:
they're generated.

## Notes

- Communication sites may already carry organisation branding from the hub.
  The theme step replaces the site's own theme only.
- The Image web part settings the script writes haven't been tried on a live
  tenant yet. If the diagram doesn't show, the caption's *Open the diagram full
  size* link still works, and you can add the image by hand from Site Assets.

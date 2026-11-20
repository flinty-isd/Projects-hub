# Control Centre Attention app (optional, Tier 1.5)

A single-screen Canvas Power App that does the one thing native SharePoint
genuinely can't: merge `SP_RAID` + `SP_Actions` + `SP_MigrationRegister` +
`SP_Decisions` into one real "Attention Required" view, instead of the four
stacked List web parts in [`../diagrams/page-layout.md`](../diagrams/page-layout.md).
Embeds into the Programme Control Centre page via the native Power Apps web
part - no separate destination for anyone to go find.

Not part of Tier 1. Build this only if the stacked-widgets version genuinely
proves inconvenient in practice - see the "Power App" discussion in this
solution's history for the reasoning.

## Two deliverables here, with very different confidence levels

| | What it is | Confidence |
|---|---|---|
| [`formulas.md`](formulas.md) | Every Power Fx formula the app needs, to paste into a blank Canvas app built by hand in Studio | **High.** Power Fx is stable and well-documented; this is ordinary formula-writing. |
| [`src/`](src) | A best-effort attempt at the modern Power Apps *source file* package (`CanvasManifest.json` + `.fx.yaml`, the format `pac canvas pack`/`unpack` and Studio's Git integration use) | **None.** Written from memory with no way to check it - no Power Platform CLI in this environment, and no network access to Microsoft's docs or a reference repo to copy from. It may not import at all. |

**Start with `formulas.md` and build the app by hand in Studio.** Try
importing `src/` only out of curiosity, or if someone with a real Power
Platform CLI setup wants to validate it first - don't block on it.

## Setup

1. Power Apps Studio → new blank Canvas app.
2. Connect the four SharePoint data sources (see `formulas.md`).
3. Build the one screen and paste in each formula from `formulas.md`.
4. Publish, then add it to the Programme Control Centre page via **Edit →
   web part → Power Apps → paste the app's Web Link**.

## Licensing - check before building

A Canvas app reading multiple SharePoint lists may need a Power Apps plan
depending on your tenant's licensing, rather than riding free within
Microsoft 365 - confirm this before investing build time, not after.

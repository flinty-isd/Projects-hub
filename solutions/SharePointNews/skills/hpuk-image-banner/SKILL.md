---
name: hpuk-image-banner
description: Create correctly sized HPUK images for SharePoint and Microsoft 365 from an authorised source image - News banners and page-title images, News thumbnails, Hero tiles, Quick Links, wide strips, supporting images, site header and logo images. Removes embedded text from flat backgrounds, recomposes around the subject with headroom, sets the focal point, checks every responsive crop, and returns a READY assessment. Use when the user says "create a SharePoint banner", "resize this for SharePoint News", "fix this banner crop", "prepare this image for SharePoint", "make a thumbnail / hero image", or "is this image suitable for a news banner".
---

# HPUK SharePoint Image Creator

Turns one authorised source image into publish-ready derivatives at the right
size for each SharePoint placement, and proves each one with a preview sheet
and checks. The source file is never changed.

## Inputs

Collect only what is needed:

- **Source image**, and whether it is an authorised HPUK image (Brand Centre,
  approved libraries, or supplied by the owner). Don't proceed on unapproved
  sources: report NOT READY.
- **Placement(s)**, mapped to presets below. Default: `news-banner`.
- **Alt text**, or that the image is decorative.

Don't delay when the placement and the problem are clear from the request.

## Presets

Sizes live in `references/presets.json` (change them there, not in the script).
Each preset says its basis: *Microsoft* guidance or *HPUK good practice*.
Label good-practice sizes as such in the report; don't present them as HPUK rules.

| Preset | Size | Use |
|---|---|---|
| `news-banner` | 1920x1080 (16:9) | News post / page title area; also the News thumbnail |
| `news-thumbnail` | 1280x720 | Separate thumbnail, when different from the banner |
| `hero` | 1920x1080 | Hero web part tile |
| `quick-links` | 1280x720 | Quick Links filmstrip/grid |
| `quick-links-icon` | 300x300 | Quick Links compact/list icon |
| `image-wide-strip` | 2560x640 (4:1) | Image web part as a strip in a full-width section |
| `supporting-image` | 1600x900 | Image web part in the page body |
| `site-header-background` | 2560x164 | Extended site header |
| `site-logo-thumbnail` | 64x64 PNG | Site logo thumbnail |

The title area is cropped differently on desktop, tablet and mobile around the
focal point. `news-banner` checks the face in each view (approximate ratios).

## Steps

1. **Classify and assess.** Name the placement and preset. Look at the source and
   note: embedded text or logos, how close the subject is to the edges,
   resolution against the target, background (flat or textured).
2. **Locate the regions** in source pixels (state the source size; if the
   displayed image is scaled, convert):
   - `--focal x,y`: centre of the face (or main subject).
   - `--face x0,y0,x1,y1`: the whole head including hair.
   - `--subject x0,y0,x1,y1`: the full visible subject.
   - `--erase x0,y0,x1,y1`: each block of embedded text (repeatable), with a
     margin. Only on flat backgrounds.
3. **Check the boxes** before rendering, then look at the overlay and correct:
   ```bash
   python scripts/make_banner.py SOURCE --focal .. --face .. --subject .. --erase .. --check-boxes --out OUT
   ```
4. **Create the derivatives:**
   ```bash
   python scripts/make_banner.py SOURCE --preset news-banner [--preset ...] \
     --focal .. --face .. --subject .. [--erase ..] \
     --allow-extend --fit-previews \
     --alt "..." --source-approved --out OUT
   ```
   - `--allow-extend` adds background (headroom, width) by repeating a flat edge.
     The script fails the check if the edge is textured.
   - `--fit-previews` zooms out until the face fits every responsive view.
   - `--zoom 1.2` crops tighter when the subject is too small.
   - Exit code 2 means NOT READY.
5. **Review visually.** Open each `*_preview.png` (coloured boxes are the
   responsive crops, the cross is the focal point) and the derivative itself.
   Look for: visible seams or leftover text where text was erased, stretched
   background, awkward cuts at joints or the top of the head, and softness when
   upscaled. If anything is wrong, adjust the boxes or zoom and re-run. Never
   report a result you haven't looked at.
6. **Report** using `*_report.md` (format below), and attach the derivatives.

## Rules

- Keep the authorised source unchanged; create new files only.
- Don't create, recreate, recolour or move logos, the Corporate Mark or other
  branding. Don't add text to images: headlines such as "Update from ..." go in
  the page title or text.
- Text removal is a flat colour fill. On photos, gradients or textures, don't
  attempt it: report "manual retouching needed" and NOT READY.
- Don't use generative fill or AI to alter people.
- Don't invent HPUK brand rules. Sources in order: Hutchison Ports Brand
  Guidelines, HPUK Brand Centre, approved HPUK brand assets and photography
  libraries, approved SharePoint standards, approved News publishing guidance,
  authorised images supplied by the user. Anything else is labelled
  **good practice**.
- Upscaling above 100% is a warning, above 150% a failure (ask for a larger
  original).

## Report format

```
Image assessment
Intended use:
Source: (name, size, approval status)
Image action selected: e.g. REMOVE EMBEDDED TEXT + RECOMPOSE + RESIZE
Action actually performed: derivatives created; source unchanged
Target dimensions: (per derivative, with basis)
Focal point: % across, % down (set in SharePoint: select image > Set focal point)
Accessibility: alt text, or empty alt if decorative beside a title naming the person
Brand/source check:
READY assessment: READY | READY WITH WARNINGS | NOT READY
Publication decision: next steps (upload, set focal point, preview desktop and mobile)
```

## Publishing in SharePoint

1. Edit the page, select the title area image, choose **Change image** and
   upload the `news-banner` file.
2. Select **Set focal point** and place it at the reported percentages.
3. Add alt text (or mark decorative).
4. **Preview** on desktop, then with a narrow window or the mobile app, before
   publishing.

## Example

Source: a 2172x724 "Update from Adam Ramsey" banner with the name as text on a
flat navy panel, and limited headroom above the head.

```bash
python scripts/make_banner.py adam-ramsey-banner.png --preset news-banner \
  --focal 1510,228 --face 1395,49,1630,391 --subject 1195,49,1835,724 \
  --erase 250,150,960,580 --allow-extend --fit-previews \
  --alt "Adam Ramsey in a dark suit and striped tie" --source-approved --out out
```

Result: text removed cleanly (flat navy); background extended 170px above;
zoomed out to 0.81 so the face fits even the wide desktop title strip; focal point
58% across, 45% down; 1920x1080, 102 KB; READY WITH WARNINGS (upscaled 121%:
check sharpness, or ask for the original photo).

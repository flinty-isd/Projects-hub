---
name: hpuk-image-banner
description: Create correctly sized HPUK images for SharePoint News banners, page-title images, thumbnails, Hero, Quick Links and site images, with focal point and READY checks. Use when the user says "create a SharePoint banner", "resize this for SharePoint News", "fix this banner crop" or "prepare this image for SharePoint".
---

# HPUK SharePoint Image Creator

## When to use

Use this skill to turn an authorised HPUK image into a new image at the right
size for SharePoint. For example:

- a News banner or page-title image
- a News thumbnail
- a Hero web part tile
- a Quick Links image or icon
- a site header or site logo

The original image is never changed. The skill always makes a new file.

## Inputs

Ask only for what is missing:

1. **The image**, and whether it is approved (Brand Centre, an approved
   library, or supplied by its owner).
2. **Where it will go** (for example, News banner).
3. **Alt text**, or confirmation that the image is decorative.

If the image is not approved, stop and report **NOT READY**.

## Sizes

Choose the size from where the image will go.

- **News banner or page title**: 1920 x 1080 (preset `news-banner`). This is also the News thumbnail.
- **Separate News thumbnail**: 1280 x 720 (`news-thumbnail`).
- **Hero tile**: 1920 x 1080 (`hero`).
- **Quick Links image**: 1280 x 720 (`quick-links`).
- **Quick Links icon**: 300 x 300 (`quick-links-icon`).
- **Wide strip in a full-width section**: 2560 x 640 (`image-wide-strip`).
- **Picture in the body of a page**: 1600 x 900 (`supporting-image`).
- **Site header background**: 2560 x 164 (`site-header-background`).
- **Site logo thumbnail**: 64 x 64 PNG (`site-logo-thumbnail`).

The sizes are kept in `references/presets.json`. Each one says whether it comes
from Microsoft guidance or is HPUK good practice. Call good-practice sizes
**good practice** in the report, not HPUK rules.

## Steps

### 1. Look at the image

Note:

- any words, names or logos inside the image
- how close the person's head is to the edges
- whether the image is big enough for the target size
- whether the background is plain colour or a photo or pattern

### 2. Mark the areas

Give each area in pixels of the original image:

- **Focal point**: the centre of the face.
- **Face**: a box around the whole head, including hair.
- **Subject**: a box around the whole person.
- **Text to remove**: a box around each block of words. Only on a plain-colour background.

A box is written `left,top,right,bottom`, for example `1395,49,1630,391`.

### 3. Check the areas

Draw the boxes on a copy and look at it. Fix any box that is wrong.

```
python scripts/make_banner.py <image> --check-boxes --focal <x,y> --face <box> --subject <box> --erase <box> --out <folder>
```

### 4. Make the new image

```
python scripts/make_banner.py <image> --preset news-banner --focal <x,y> --face <box> --subject <box> --erase <box> --allow-extend --fit-previews --alt "<alt text>" --source-approved --out <folder>
```

What the options do:

- `--preset`: the size. Repeat it to make more than one size.
- `--erase`: removes words on a plain background. Repeat it for each block.
- `--allow-extend`: adds plain background, for example space above the head.
- `--fit-previews`: zooms out until the face shows in every desktop and mobile view.
- `--zoom 1.2`: crops in closer when the person is too small.

### 5. Check the result yourself

Open the new image and its `_preview.png` file. The coloured boxes show what
SharePoint shows on desktop, tablet and mobile. The cross is the focal point.

Look for:

- traces of removed words
- a visible join or stretched background
- the top of the head or chin cut off
- a blurred picture (when the original was too small)

If something is wrong, change the boxes or zoom and make it again. Don't report
a result you haven't looked at.

### 6. Report

Use the `_report.md` file. Give the new image to the user.

## Rules

- Never change the original image.
- Never add, recreate, recolour or move logos or the Corporate Mark.
- Never put words in the image. Headlines such as "Update from ..." go in the page title.
- Only remove words from a plain-colour background. On a photo or pattern, report **manual retouching needed** and **NOT READY**.
- Never use AI to change how a person looks.
- Enlarging above 100% is a warning. Above 150% is NOT READY: ask for a bigger original.
- Don't invent HPUK brand rules. Use these sources, in this order:
  1. Hutchison Ports Brand Guidelines
  2. HPUK Brand Centre
  3. Approved HPUK brand assets and photography libraries
  4. Approved HPUK SharePoint standards
  5. Approved HPUK News publishing guidance
  6. Authorised images supplied by the user

## Report

Return:

- **Intended use**
- **Source**: file name, size, and whether it is approved
- **Image action selected**: for example, remove embedded text, recompose, resize
- **Action actually performed**: new image created; original unchanged
- **Target size**, and whether it is Microsoft guidance or good practice
- **Focal point**: % across and % down
- **Accessibility**: the alt text. Use empty alt text if the image is decorative beside a title that names the person.
- **Brand/source check**
- **READY assessment**: READY, READY WITH WARNINGS, or NOT READY
- **Publication decision**: what to do next

## Publishing in SharePoint

1. Edit the page. Select the title-area image and choose **Change image**.
2. Upload the new image.
3. Select **Set focal point** and place it at the reported position.
4. Add the alt text, or mark the image as decorative.
5. Preview on desktop and on a narrow window or phone before you publish.

## Example

The "Update from Adam Ramsey" banner is 2172 x 724, with the name written on a
plain navy panel and little space above his head.

```
python scripts/make_banner.py adam-ramsey-banner.png --preset news-banner --focal 1510,228 --face 1395,49,1630,391 --subject 1195,49,1835,724 --erase 250,150,960,580 --allow-extend --fit-previews --alt "Adam Ramsey in a dark suit and striped tie" --source-approved --out out
```

Result:

- The words were removed cleanly.
- Plain background was added above his head.
- His face shows in every desktop and mobile view.
- The focal point is 58% across and 45% down.
- The image is 1920 x 1080 and 102 KB.
- **READY WITH WARNINGS**: the original was enlarged to 121%, so check it is sharp, or ask for the original photo.

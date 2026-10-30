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

Everything the skill needs is in this file. The image code is at the end, in
**Image code**. Run it with your code tool (code interpreter).

## Inputs

Ask only for what is missing:

1. **The image**, and whether it is approved (Brand Centre, an approved
   library, or supplied by its owner).
2. **Where it will go** (for example, News banner).
3. **Alt text**, or confirmation that the image is decorative.

If the image is not approved, stop and report **NOT READY**.

## Sizes

Choose the size from where the image will go.

- **News banner or page title**: 1920 x 1080. This is also the News thumbnail.
- **Separate News thumbnail**: 1280 x 720.
- **Hero tile**: 1920 x 1080.
- **Quick Links image**: 1280 x 720.
- **Quick Links icon**: 300 x 300.
- **Wide strip in a full-width section**: 2560 x 640.
- **Picture in the body of a page**: 1600 x 900.
- **Site header background**: 2560 x 164.
- **Site logo thumbnail**: 64 x 64.

News banner, thumbnail, Hero, header and logo sizes follow Microsoft guidance.
The others are **good practice**. Call them good practice in the report, not
HPUK rules.

## Steps

### 1. Look at the image

Note:

- the image size in pixels
- any words, names or logos inside the image
- how close the person's head is to the edges
- whether the image is big enough for the target size
- whether the background is plain colour or a photo or pattern

### 2. Mark the areas

Give each area in pixels of the original image:

- **Focal point**: the centre of the face, as (x, y).
- **Face**: a box around the whole head, including hair.
- **Subject**: a box around the whole person.
- **Words to remove**: a box around each block of words. Only on a plain-colour background.

A box is written (left, top, right, bottom), for example (1395, 49, 1630, 391).

Draw the boxes on a copy of the image and look at it. Fix any box that is wrong.

### 3. Make the new image

Run the **Image code** with the image, the size and the areas. For example:

```
make_image("banner.png", "banner_1920x1080.jpg", 1920, 1080,
           focal=(1510, 228), face=(1395, 49, 1630, 391),
           subject=(1195, 49, 1835, 724), erase=[(250, 150, 960, 580)])
```

The code:

- removes the words by filling them with the background colour
- adds plain background above the head if it is too close to the top
- zooms out until the face shows in the desktop, tablet, card and mobile views
- crops, resizes and saves the new image
- returns the focal point and any warnings

For a size other than the News banner, change the width and height. For a
square icon, use `views=(1.0,)`.

If you can't run code, don't make up a result. Report the size, the areas from
step 2 and **Action actually performed: not performed**, so someone else can make it.

### 4. Check the result yourself

Look at the new image. Look for:

- traces of removed words
- a visible join or stretched background
- the top of the head or chin cut off
- a blurred picture (when the original was too small)

If something is wrong, change the boxes and make it again. Don't report a result
you haven't looked at.

### 5. Report

Use the report format below. Give the new image to the user.

## Rules

- Never change the original image.
- Never add, recreate, recolour or move logos or the Corporate Mark.
- Never put words in the image. Headlines such as "Update from ..." go in the page title.
- Only remove words from a plain-colour background. On a photo or pattern, report **manual retouching needed** and **NOT READY**.
- Never use AI to change how a person looks.
- Enlarging above 100% is a warning. Above 150% is NOT READY: ask for a bigger original.
- Any note starting "NOT READY" from the code means the result is NOT READY.
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
- **Focal point**: % across and % down (from the code)
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
plain navy panel and little space above his head. Running the example in step 3
gives:

- The words removed cleanly.
- 170 pixels of plain background added above his head.
- His face showing in every desktop and mobile view.
- Focal point 58% across and 45% down.
- A 1920 x 1080 image.
- **READY WITH WARNINGS**: the original was enlarged to 121%, so check it is sharp, or ask for the original photo.

## Image code

Python, using Pillow and numpy.

```python
from PIL import Image
import numpy as np

def make_image(source, output, width, height, focal, face, subject,
               erase=(), headroom=0.12, views=(4.0, 2.0, 16/9, 4/3)):
    """Make a width x height image. Boxes are (left, top, right, bottom) in source pixels."""
    img = np.array(Image.open(source).convert("RGB"))
    H, W = img.shape[:2]
    notes = []

    # 1. Remove words: fill each box with the colour just around it.
    for x0, y0, x1, y1 in erase:
        ring = np.concatenate([img[max(0, y0-8):y0, x0:x1].reshape(-1, 3), img[y1:y1+8, x0:x1].reshape(-1, 3),
                               img[y0:y1, max(0, x0-8):x0].reshape(-1, 3), img[y0:y1, x1:x1+8].reshape(-1, 3)])
        if ring.std(axis=0).max() > 6:
            notes.append("NOT READY: background behind the words is not plain; retouch by hand")
        img[y0:y1, x0:x1] = np.median(ring, axis=0)

    ratio = width / height
    def boxes_for(zoom):
        ch = H / zoom
        cw = ch * ratio
        if cw > W / zoom:
            cw = W / zoom; ch = cw / ratio
        left = min(max(focal[0] - cw/2, 0), W - cw) if cw <= W else focal[0] - cw/2
        top = min(max(focal[1] - ch/2, 0), H - ch) if ch <= H else H - ch
        top = min(top, subject[1] - headroom * ch)          # space above the head
        return left, top, cw, ch

    def face_fits(left, top, cw, ch):
        s = width / cw
        fx, fy = (focal[0]-left)*s, (focal[1]-top)*s
        fb = [(face[0]-left)*s, (face[1]-top)*s, (face[2]-left)*s, (face[3]-top)*s]
        for r in views:  # SharePoint crops each view around the focal point
            pw, ph = (height*r, height) if width/height > r else (width, width/r)
            vx = min(max(fx-pw/2, 0), width-pw); vy = min(max(fy-ph/2, 0), height-ph)
            if fb[0] < vx or fb[1] < vy or fb[2] > vx+pw or fb[3] > vy+ph:
                return False
        return True

    # 2. Zoom out until the face shows in every view.
    zoom = 1.0
    while not face_fits(*boxes_for(zoom)) and zoom > 0.4:
        zoom *= 0.9
    left, top, cw, ch = boxes_for(zoom)

    # 3. Add plain background where the crop goes past the edge.
    pad = [int(np.ceil(max(0, v))) for v in (-left, -top, left+cw-W, top+ch-H)]
    for side, p in zip("ltrb", pad):
        if not p:
            continue
        edge = {"l": img[:, :8], "t": img[:8], "r": img[:, -8:], "b": img[-8:]}[side]
        axis = 1 if side in "lr" else 0
        if edge.std(axis=axis).mean() > 6:
            notes.append("NOT READY: edge is not plain, so extra background would look stretched")
        line = np.expand_dims(np.median(edge, axis=axis), axis)
        fill = np.repeat(line, p, axis=axis).astype(np.uint8)
        img = np.concatenate([fill, img] if side in "lt" else [img, fill], axis=axis)
    left, top = left + pad[0], top + pad[1]

    # 4. Crop, resize and save.
    out = Image.fromarray(img).crop((round(left), round(top), round(left+cw), round(top+ch)))
    out = out.resize((width, height), Image.LANCZOS)
    out.save(output, quality=85, optimize=True, progressive=True)

    scale = width / cw
    if scale > 1.5: notes.append(f"NOT READY: enlarged {scale:.0%}; ask for a bigger original")
    elif scale > 1.0: notes.append(f"WARNING: enlarged {scale:.0%}; check it is sharp")
    if not face_fits(left - pad[0], top - pad[1], cw, ch):
        notes.append("NOT READY: face is cut off in at least one view")
    fx = round((focal[0] - left + pad[0]) * scale / width * 100)
    fy = round((focal[1] - top + pad[1]) * scale / height * 100)
    return {"file": output, "size": f"{width}x{height}", "focal_point": f"{fx}% across, {fy}% down",
            "zoom": round(zoom, 2), "added_background_px": dict(zip(["left", "top", "right", "bottom"], pad)),
            "notes": notes}
```

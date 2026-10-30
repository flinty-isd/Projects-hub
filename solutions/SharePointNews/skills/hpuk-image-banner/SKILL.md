---
name: hpuk-image-banner
description: Prepare correctly sized images for HPUK SharePoint News posts - the News banner (which is also the thumbnail), a separate thumbnail, and pictures in the body of the post. Works out the exact crop, size and focal point, and gives the publisher step-by-step instructions to make the image in Paint and add it to the News post. Use when the user says "create a News banner", "resize this for SharePoint News", "fix this banner crop" or "is this image suitable for a News post".
---

# HPUK News Post Image Creator

## When to use

Use this skill for images in an HPUK SharePoint **News post**:

- the **News banner** at the top of the post (the title-area image)
- the **News thumbnail**, when it should differ from the banner
- **pictures in the body** of the post (Image or Image gallery web part)

It isn't for other pages or site images (Hero, Quick Links, site logo or header).
For those, say the skill doesn't cover them.

## How it works

This skill can't edit image files itself. Instead it:

1. looks at the image and finds what needs fixing
2. works out the exact numbers: what to cover, what to add, where to crop, and the final size
3. gives the publisher a short recipe to make the new image in **Paint** (built into Windows)
4. gives the News post steps, including where to set the focal point

The original image is never changed. The publisher saves a new copy first.

## Inputs

Ask only for what is missing:

1. **The image**, and whether it is approved (Brand Centre, an approved library, or supplied by its owner).
2. **Where it goes in the post**: the banner, the thumbnail, or the body. If not
   said, assume the banner.
3. **Alt text**, or confirmation that the image is decorative.

If the image is not approved, stop and report **NOT READY**.

## Sizes

- **News banner**: 1920 x 1080 (16:9). It is also the thumbnail on HPUK News
  and the intranet home, so it must work small as well as large.
- **Separate News thumbnail**: 1280 x 720 (16:9). Only when the banner doesn't
  work as a thumbnail.
- **Picture in the body of the post**: 1600 x 900 (16:9) for a wide picture.
  Other shapes are fine in the body: keep the picture's own shape and make it no
  wider than 1600.

The banner and thumbnail sizes follow Microsoft guidance and the HPUK Publisher
Guide (16:9). The body size is **good practice**. Say so in the report; don't
call it an HPUK rule.

## Different kinds of picture

First decide what kind of picture it is. Then follow its rules in the steps below.

**One person on a plain background** (for example, a studio portrait)

- Focal point: the centre of the face.
- You can cover words and add background (steps 2a and 2b).

**One person in a real setting** (for example, on the quayside)

- Focal point: the centre of the face.
- Don't cover words or add background: it won't match the photo.
- Crop only. If the head is more than 40% of the height, the picture is too
  close-up for a News banner: ask for a wider shot, or use it in the page body
  instead.

**A group of people**

- Treat all the heads together as the "head": from the highest hair to the lowest chin.
- Focal point: the middle of the group.
- Every face must be inside the crop. If the group is too wide for the shape,
  say so: don't cut anyone off at the edge.

**A place, ship, crane or equipment, with no people in focus**

- Focal point: the main subject (for example, the ship's bow or the crane).
- Keep the main subject no taller than 40% of the height, the same as a head.
- Don't add background or cover anything. Crop only.
- Keep the horizon off the exact middle where you can.

**A tall (portrait) photo for a wide banner**

- Only a slice of it will fit. Crop a wide slice around the subject.
- If the slice is too small (enlargement over 150%), say it is **NOT READY**
  for a banner and suggest the page body instead, or ask for a landscape photo.

**A poster, event graphic or anything with words on a photo**

- Not suitable as a banner or thumbnail: the words get cut off and screen
  readers can't read them. Report **NOT READY**.
- Ask Communications for a version without words, and put the words in the
  page. The graphic can go in the page body, with the words in its alt text.

**A logo on its own**

- Not suitable as a banner. A logo in a post goes in the body.
- Use the version from the HPUK Brand Centre. Don't make or resize logos in
  Paint: it loses the transparent background.
- Never recolour, stretch or redraw a logo.

**A screenshot, chart or document**

- Not suitable as a banner. Use it in the page body at its own size: never
  enlarge it.
- Describe what it shows in the alt text or the page text.

## Steps

### 1. Look at the image

Note:

- the image width and height in pixels
- any words, names or logos inside the image
- where the person's head is: the top of the hair, the chin, and the centre of the face
- whether the background is plain colour or a photo or pattern

### 2. Work out the numbers

Use pixels of the original image. Positions are from the top-left corner.

**a. Words to cover.** Give a box around each block of words, with a small margin.
Only cover words on a plain-colour background. If the words sit on a photo or
pattern, stop: report **manual retouching needed** and **NOT READY**.

**b. Space for the head.** SharePoint shows News banners as a thin strip on wide
screens. So the head (top of hair to chin), or the main subject in a picture
without people, must be no more than **40%** of the final height.

- Needed height = head height ÷ 0.4
- If the image is shorter than that, add the difference as plain background at
  the **top** (only if the top edge is plain colour).
- Also keep at least **10%** of the height as space above the hair.

**c. Crop box.** For the target shape (16:9 = width is 1.78 x height):

- Crop height = the image height (after step b).
- Crop width = crop height x 1.78. If that is wider than the image, use the full
  width and work out the height instead (width ÷ 1.78).
- Centre the crop across on the face, then move it so it stays inside the image.
- Check the crop doesn't include any words you didn't cover.
- For a picture in the body that keeps its own shape, skip the crop: just
  resize it to no wider than 1600.

**d. Size check.** Enlargement = final width ÷ crop width.

- 100% or less: fine.
- Over 100%: warning, check it is sharp.
- Over 150%: **NOT READY**. Ask for a bigger original.

**e. Focal point.** Where the centre of the face lands in the crop:

- across = (face centre x − crop left) ÷ crop width, as a %
- down = (face centre y + space added at the top) ÷ crop height, as a %

Your positions are estimates from looking at the image. Tell the publisher they
can check them by hovering in Paint: the position shows at the bottom left.

### 3. Give the Paint recipe

Fill in the numbers. Leave out steps that aren't needed.

1. Open the image in **Paint**. Choose **File > Save as > JPEG** and save a copy
   called `<name>_<use>_<width>x<height>.jpg`. Work on the copy only.
2. **Cover the words** (for each box):
   - Choose the **Colour picker** and click the background just next to the words.
   - Choose **Shapes > Rectangle**, set **Fill** to **Solid colour** and
     **Outline** to **No outline**.
   - Drag from (x, y) to (x, y). Watch the position at the bottom left.
3. **Add space at the top** (N pixels):
   - Choose **Image > Flip > Flip vertical**.
   - Drag the handle in the middle of the bottom edge down until the size at
     the bottom shows <width> x <new height>.
   - Fill the new white area with the background colour: pick the colour from
     just inside the old edge, then draw solid rectangles over the white area.
     Where the background has two colours, draw one rectangle for each, matching
     where the colours meet.
   - Choose **Image > Flip > Flip vertical** again.
4. **Crop**: choose **Select > Rectangle**, drag from (x, y) to (x, y) until the
   selection size at the bottom shows about <width> x <height>, then choose
   **Crop**. A few pixels out doesn't matter.
5. **Resize**: choose **Image > Resize and skew**, choose **Pixels**, untick
   **Maintain aspect ratio**, and enter <final width> x <final height>.
6. **Save** (Ctrl+S).

### 4. Give the News post steps

**News banner**

1. Edit the News post. Select the image at the top and choose **Change image**.
2. Upload the new image.
3. Select **Set focal point** and place it <across>% across and <down>% down
   (on the face or main subject).
4. Add the alt text, or mark the image as decorative.

**Separate thumbnail** (only if needed)

1. Open **Page details**. Under **Thumbnail**, choose **Change** and upload it.

**Picture in the body**

1. Add an **Image** web part (or **Image gallery** for several), upload the
   picture and add alt text.

**Before publishing**

1. Preview on desktop and on a narrow window or phone.
2. Check the post's card on HPUK News looks right.

### 5. Report

Return:

- **Intended use**
- **Source**: file name, size, and whether it is approved
- **Image action selected**: for example, cover embedded text, add space, crop, resize
- **Action actually performed**: recipe provided; the publisher makes the image. Original unchanged.
- **Target size**, and whether it is Microsoft guidance or good practice
- **Focal point**: % across and % down
- **Accessibility**: the alt text. Use empty alt text if the image is decorative beside a title that names the person.
- **Brand/source check**
- **READY assessment**: READY, READY WITH WARNINGS, or NOT READY
- **Publication decision**: what to do next
- The **Paint recipe** and **News post steps** from steps 3 and 4

## Rules

- Never change the original image. Always save a copy first.
- Never add, recreate, recolour or move logos or the Corporate Mark.
- Never put words in the image. Headlines such as "Update from ..." go in the page title.
- Only cover words or add background on plain colour. On a photo or pattern, report **manual retouching needed** and **NOT READY**.
- Never use AI tools (such as generative erase) to change how a person looks.
- Don't claim an image was made: the publisher makes it from the recipe.
- Don't invent HPUK brand rules. Use these sources, in this order:
  1. Hutchison Ports Brand Guidelines
  2. HPUK Brand Centre
  3. Approved HPUK brand assets and photography libraries
  4. Approved HPUK SharePoint standards
  5. Approved HPUK News publishing guidance
  6. Authorised images supplied by the user

## Example

**Image:** "Update from Adam Ramsey" banner, 2172 x 724. The name is written on a
plain navy panel on the left (0 to 1351 across). Light blue on the right
(1352 to 2172). Head: hair top at 49, chin at 391 (342 high); face centre at
1510 across, 228 down.

**Numbers:**

- Cover words: box from (250, 150) to (960, 580), navy.
- Needed height: 342 ÷ 0.4 = 855. Add 855 − 724 = **131 pixels** at the top.
- Crop: height 855, width 855 x 1.78 = 1520. Centred on 1510 it would end past
  2172, so it moves left: from (652, 0) to (2172, 855).
- Enlargement: 1920 ÷ 1520 = 126%: **warning**, check it is sharp.
- Focal point: across (1510 − 652) ÷ 1520 = **56%**; down (228 + 131) ÷ 855 = **42%**.

**Paint recipe:**

1. Save a copy as `adam-ramsey_news-banner_1920x1080.jpg`.
2. Pick the navy next to the words. Draw a solid rectangle from (250, 150) to (960, 580).
3. Flip vertical. Drag the bottom edge down until the size shows 2172 x 855.
   Pick the navy just above the join and draw a solid rectangle from (0, 724) to
   (1351, 855). Pick the light blue just above the join and draw one from
   (1352, 724) to (2172, 855). Flip vertical again.
4. Select from (652, 0) to (2172, 855) (about 1520 x 855) and crop.
5. Resize to 1920 x 1080 in pixels, with **Maintain aspect ratio** unticked.
6. Save.

**SharePoint:** focal point 56% across, 42% down. Alt text: "Adam Ramsey in a
dark suit and striped tie", or empty if the page title already names him.

**READY assessment:** READY WITH WARNINGS (enlarged 126%: check it is sharp, or
ask for the original photo).

## Example: a photo with no people

**Image:** a 4000 x 3000 photo of a crane at Felixstowe. The crane is 900 high,
centred at 2600 across, 1400 down. No words.

**Numbers:**

- Nothing to cover. The crane is 900 ÷ 2250 = 40% of the crop height: just fits.
- Crop: 4000 x 1.78 would need a height of 2250, which fits in 3000. So use the
  full width, 4000 x 2250. Centred on 1400 down, it runs from (0, 275) to (4000, 2525).
- Enlargement: 1920 ÷ 4000 = 48%: fine, it gets smaller.
- Focal point: across 2600 ÷ 4000 = **65%**; down (1400 − 275) ÷ 2250 = **50%**.

**Paint recipe:** save a copy, select from (0, 275) to (4000, 2525) and crop,
resize to 1920 x 1080, save.

**READY assessment:** READY.

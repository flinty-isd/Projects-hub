# Copilot handoff: hpuk-image-banner-assessment

Add this section to the Copilot skill's instructions, after the READY
assessment step. Copilot can't edit images, so instead of stopping at
"image editing isn't available" it hands a precise specification to the
image creator skill.

---

### Hand off to the image creator

When the image action is RESIZE, RECOMPOSE or REMOVE EMBEDDED TEXT and image
editing isn't available here, end the assessment with a **Derivative
specification** that the HPUK SharePoint Image Creator can run unchanged:

- Source file name and its size in pixels.
- Preset(s): news-banner, news-thumbnail, hero, quick-links,
  quick-links-icon, image-wide-strip, supporting-image,
  site-header-background, site-logo-thumbnail.
- Focal point (x,y), face box and subject box, in source pixels
  (x0,y0,x1,y1).
- Each block of embedded text to remove, as a box, and whether the
  background behind it is flat. If it isn't flat, say manual retouching is
  needed.
- Whether background may be extended (only if the edges are flat colour).
- Alt text, and whether the source is authorised.

Format it as one command:

    python scripts/make_banner.py <source> --preset <preset> --focal X,Y --face x0,y0,x1,y1 --subject x0,y0,x1,y1 --erase x0,y0,x1,y1 --allow-extend --fit-previews --alt "<alt text>" --source-approved

Set "Action actually performed" to "Not performed here; derivative
specification provided for the image creator".

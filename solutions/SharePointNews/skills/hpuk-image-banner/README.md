# HPUK SharePoint Image Creator (skill)

Creates correctly sized SharePoint images (News banner, thumbnail, Hero,
Quick Links, wide strip, supporting image, site header and logo) from an
authorised source. It removes embedded text from flat backgrounds, recomposes
with headroom, checks the face in every responsive crop, and writes a READY
report. It completes the **hpuk-image-banner-assessment** Copilot skill: that
skill assesses the image and stops at "image editing isn't available"; this one
makes the derivative.

| File | What it is |
|---|---|
| [`SKILL.md`](SKILL.md) | The skill. **Self-contained**: instructions, sizes and the image code in one file, so it works where only the instructions can be loaded (for example a SharePoint/Copilot skill with code interpreter) |
| [`scripts/make_banner.py`](scripts/make_banner.py) | Optional fuller version for running locally: preview sheets, file-size limits, Markdown/JSON reports |
| [`references/presets.json`](references/presets.json) | Target sizes, file-size limits, responsive previews and thresholds. Edit sizes here |
| [`copilot-handoff.md`](copilot-handoff.md) | Text to add to the Copilot assessment skill so its output feeds this skill |

## Run it

```bash
pip install pillow numpy
python scripts/make_banner.py source.png --check-boxes --focal X,Y --face ... --subject ... --erase ... --out out
python scripts/make_banner.py source.png --preset news-banner --focal X,Y --face ... --subject ... \
  --erase ... --allow-extend --fit-previews --alt "..." --source-approved --out out
```

Output in `out/`: one image per preset, a `*_preview.png` per preset showing
the responsive crops, and `*_report.md` / `*_report.json`. Exit code 2 means
NOT READY.

## Package as a skill

```bash
cd .. && zip -r hpuk-image-banner.skill hpuk-image-banner -x '*/out/*' '*/__pycache__/*'
```

## Sizes to confirm

Sizes marked *Microsoft* follow Microsoft's SharePoint image guidance; those
marked *HPUK good practice* are working values. Communications should confirm
them against the Brand Centre and News publishing guidance, then update
`presets.json`. The desktop, tablet and mobile title-area ratios are
approximations of how SharePoint crops around the focal point; always preview
the page before publishing.

#!/usr/bin/env python3
"""Make correctly sized SharePoint images from an authorised source image.

Creates one derivative per preset (see presets.json): removes
embedded text from flat backgrounds, recomposes around a focal point with
headroom, resizes, compresses, and validates the result against READY checks.
The source file is never changed.

Example:
  python make_banner.py source.png --preset news-banner \
      --focal 1395,215 --face 1290,70,1500,330 --subject 1110,45,1690,724 \
      --erase 250,160,860,520 --allow-extend \
      --alt "Adam Ramsey in a dark suit and striped tie" --source-approved \
      --out ./out
"""
import argparse
import json
import sys
from datetime import date
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageOps

HERE = Path(__file__).resolve().parent
PRESETS = HERE / "presets.json"


def parse_nums(text, n, name):
    try:
        vals = [float(v) for v in text.split(",")]
    except ValueError:
        vals = []
    if len(vals) != n:
        raise argparse.ArgumentTypeError(f"{name} needs {n} comma-separated numbers, got '{text}'")
    return vals


def box(text):
    x0, y0, x1, y1 = parse_nums(text, 4, "box")
    if x1 <= x0 or y1 <= y0:
        raise argparse.ArgumentTypeError(f"box '{text}' must be x0,y0,x1,y1 with x1>x0 and y1>y0")
    return (x0, y0, x1, y1)


def point(text):
    return tuple(parse_nums(text, 2, "point"))


def erase(arr, b, ring=8):
    """Fill box b with the median colour of a ring just outside it.

    Only suitable for flat or near-flat backgrounds; the ring's spread is
    returned so the caller can flag textured backgrounds for manual editing.
    """
    h, w = arr.shape[:2]
    x0, y0, x1, y1 = (int(round(v)) for v in b)
    x0, y0, x1, y1 = max(0, x0), max(0, y0), min(w, x1), min(h, y1)
    ox0, oy0, ox1, oy1 = max(0, x0 - ring), max(0, y0 - ring), min(w, x1 + ring), min(h, y1 + ring)
    mask = np.zeros((h, w), bool)
    mask[oy0:oy1, ox0:ox1] = True
    mask[y0:y1, x0:x1] = False
    ring_px = arr[mask].astype(float)
    colour = np.median(ring_px, axis=0)
    spread = float(ring_px.std(axis=0).max())
    arr[y0:y1, x0:x1] = colour.astype(arr.dtype)
    return {"box": [x0, y0, x1, y1], "fill_rgb": [int(c) for c in colour], "background_std": round(spread, 1)}


def edge_std(arr, side, depth=4):
    strip = {"top": arr[:depth], "bottom": arr[-depth:], "left": arr[:, :depth], "right": arr[:, -depth:]}[side]
    # Spread along the edge doesn't matter (each row/column is replicated on its own);
    # what matters is how much each replicated line changes across the strip's depth.
    axis = 0 if side in ("top", "bottom") else 1
    return float(strip.astype(float).std(axis=axis).mean())


def smooth_line(lines, axis, window=15):
    """Median of the edge lines, then a median filter along the edge: removes grain but keeps sharp colour boundaries."""
    line = np.median(lines.astype(float), axis=axis)
    padded = np.pad(line, ((window // 2, window // 2), (0, 0)), mode="edge")
    return np.median(np.lib.stride_tricks.sliding_window_view(padded, window, axis=0), axis=-1)


def extend(arr, left, top, right, bottom, depth=8):
    """Add background on each side by repeating a de-grained copy of that edge."""
    if top or bottom:
        t = np.repeat(smooth_line(arr[:depth], 0)[None], top, axis=0)
        b = np.repeat(smooth_line(arr[-depth:], 0)[None], bottom, axis=0)
        arr = np.concatenate([t, arr, b], axis=0)
    if left or right:
        l = np.repeat(smooth_line(arr[:, :depth], 1)[:, None], left, axis=1)
        r = np.repeat(smooth_line(arr[:, -depth:], 1)[:, None], right, axis=1)
        arr = np.concatenate([l, arr, r], axis=1)
    return arr.round().astype(np.uint8)


def plan_crop(W, H, ratio, focal, subject, headroom, zoom):
    """Return the crop (left, top, width, height) in source pixels; may extend past the image."""
    ch = H / zoom
    cw = ch * ratio
    if cw > W / zoom:
        cw = W / zoom
        ch = cw / ratio
    fx, fy = focal
    # Inside the image, centre on the focal point; when zoomed out past the
    # image, centre across and keep the bottom edge (portraits are cut at the chest).
    left = min(max(fx - cw / 2, 0), W - cw) if cw <= W else fx - cw / 2
    top = min(max(fy - ch / 2, 0), H - ch) if ch <= H else H - ch
    if subject:
        sx0, sy0, sx1, sy1 = subject
        # Headroom above the subject; may push the crop above the image (padded later).
        if sy0 - top < headroom * ch:
            top = sy0 - headroom * ch
        # Keep the whole subject width in frame where it fits.
        if sx1 - sx0 <= cw:
            if sx0 < left:
                left = sx0
            if sx1 > left + cw:
                left = sx1 - cw
    return left, top, cw, ch


def preview_box(w, h, ratio, focal):
    """SharePoint crops responsive views around the focal point; approximate that."""
    if w / h > ratio:
        ph, pw = h, h * ratio
    else:
        pw, ph = w, w / ratio
    fx, fy = focal
    left = min(max(fx - pw / 2, 0), w - pw)
    top = min(max(fy - ph / 2, 0), h - ph)
    return left, top, left + pw, top + ph


def contains(outer, inner):
    return outer[0] <= inner[0] and outer[1] <= inner[1] and outer[2] >= inner[2] and outer[3] >= inner[3]


def visible_share(outer, inner):
    ix = max(0, min(outer[2], inner[2]) - max(outer[0], inner[0]))
    iy = max(0, min(outer[3], inner[3]) - max(outer[1], inner[1]))
    area = (inner[2] - inner[0]) * (inner[3] - inner[1])
    return ix * iy / area if area else 1.0


def save(img, path, fmt, max_kb):
    if fmt == "png":
        img.save(path, "PNG", optimize=True)
        return None
    for q in range(88, 59, -4):
        img.save(path, "JPEG", quality=q, optimize=True, progressive=True)
        if path.stat().st_size <= max_kb * 1024:
            return q
    return q


def make(src_arr, name, preset, args, thresholds, out_dir, stem):
    H, W = src_arr.shape[:2]
    tw, th = preset["width"], preset["height"]
    ratio = tw / th
    focal = args.focal or (W / 2, H / 2)
    left, top, cw, ch = plan_crop(W, H, ratio, focal, args.subject, args.headroom, args.zoom)

    checks, notes = [], []
    pad = [max(0, -left), max(0, -top), max(0, left + cw - W), max(0, top + ch - H)]
    pad = [int(np.ceil(p)) for p in pad]
    arr = src_arr
    if any(pad):
        if not args.allow_extend:
            # Without extension, pull the crop back inside the image (less headroom).
            left = min(max(left, 0), W - cw)
            top = min(max(top, 0), H - ch)
            pad = [0, 0, 0, 0]
            checks.append(("warn", "Limited headroom: the subject is close to the top edge. Re-run with --allow-extend to add background above, or choose another source."))
        else:
            for side, p in zip(("left", "top", "right", "bottom"), pad):
                if p:
                    s = edge_std(src_arr, side)
                    ok = s <= thresholds["edge_uniform_std"]
                    checks.append(("pass" if ok else "fail",
                                   f"Extended background {side} by {p}px (edge variation {s:.1f}; "
                                   + ("flat, extension is seamless)" if ok else "textured, extension will look stretched: edit manually)")))
            arr = extend(src_arr, *pad)
            left += pad[0]
            top += pad[1]

    crop = Image.fromarray(arr).crop((round(left), round(top), round(left + cw), round(top + ch)))
    scale = tw / cw
    out = crop.resize((tw, th), Image.LANCZOS)

    if scale > thresholds["upscale_fail"]:
        checks.append(("fail", f"Source too small: upscaled {scale:.0%}. Ask for a higher-resolution original."))
    elif scale > thresholds["upscale_warn"]:
        checks.append(("warn", f"Upscaled {scale:.0%} from the source; check sharpness at 100% before publishing."))
    else:
        checks.append(("pass", f"Downscaled to {scale:.0%}: no loss of sharpness."))

    def to_out(x, y):
        return ((x + pad[0] - left) * scale, (y + pad[1] - top) * scale)

    f_out = to_out(*focal)
    face_out = (*to_out(*args.face[:2]), *to_out(*args.face[2:])) if args.face else None
    subj_out = (*to_out(*args.subject[:2]), *to_out(*args.subject[2:])) if args.subject else None
    if subj_out:
        hr = subj_out[1] / th
        checks.append(("pass" if hr >= args.headroom * 0.9 else "warn",
                       f"Headroom above subject: {hr:.0%} of the height (target {args.headroom:.0%})."))

    previews = []
    for label, r in preset.get("previews", {}).items():
        pb = preview_box(tw, th, r, f_out)
        face_ok = contains(pb, face_out) if face_out else None
        share = visible_share(pb, subj_out) if subj_out else None
        previews.append({"view": label, "ratio": round(r, 3), "box": [round(v) for v in pb],
                         "face_fully_visible": face_ok,
                         "subject_visible": None if share is None else round(share, 2)})
        if face_ok is False:
            checks.append(("fail", f"{label}: the face is cut off. Move the focal point or recompose."))
        elif face_ok:
            checks.append(("pass", f"{label}: face fully visible."))

    fmt = preset.get("format", args.format)
    out_path = out_dir / f"{stem}_{name}_{tw}x{th}.{'png' if fmt == 'png' else 'jpg'}"
    quality = save(out.convert("RGB"), out_path, fmt, preset["max_kb"])
    kb = out_path.stat().st_size / 1024
    checks.append(("pass" if kb <= preset["max_kb"] else "warn",
                   f"File size {kb:.0f} KB (limit {preset['max_kb']} KB)" + (f", JPEG quality {quality}." if quality else ".")))
    checks.insert(0, ("pass", f"Dimensions {tw}x{th} ({preset['ratio']}), as {preset['basis']}."))

    sheet = out_dir / f"{stem}_{name}_preview.png"
    draw_sheet(out, f_out, face_out, previews, sheet)

    return {
        "preset": name, "label": preset["label"], "basis": preset["basis"],
        "file": out_path.name, "preview_sheet": sheet.name,
        "width": tw, "height": th, "kb": round(kb),
        "source_crop": [round(left - pad[0]), round(top - pad[1]), round(left - pad[0] + cw), round(top - pad[1] + ch)],
        "extended_px": dict(zip(("left", "top", "right", "bottom"), pad)),
        "scale": round(scale, 3),
        "focal_point_px": [round(v) for v in f_out],
        "focal_point_pct": [round(f_out[0] / tw * 100), round(f_out[1] / th * 100)],
        "previews": previews,
        "checks": [{"result": r, "detail": d} for r, d in checks],
    }


def draw_sheet(img, focal, face, previews, path):
    sheet = img.copy().convert("RGB")
    sheet.thumbnail((1400, 1400))
    k = sheet.width / img.width
    d = ImageDraw.Draw(sheet)
    colours = ["#ff3b30", "#ffcc00", "#34c759", "#0a84ff", "#bf5af2"]
    for i, p in enumerate(previews):
        b = [v * k for v in p["box"]]
        c = colours[i % len(colours)]
        d.rectangle(b, outline=c, width=3)
        d.text((b[0] + 6, b[1] + 6 + 14 * i), p["view"], fill=c)
    if face:
        d.rectangle([v * k for v in face], outline="#ffffff", width=1)
    fx, fy = focal[0] * k, focal[1] * k
    d.line((fx - 10, fy, fx + 10, fy), fill="#ff3b30", width=2)
    d.line((fx, fy - 10, fx, fy + 10), fill="#ff3b30", width=2)
    sheet.save(path)


def fit(arr, name, preset, args, th, stem):
    base = args.zoom
    result = make(arr, name, preset, args, th, args.out, stem)
    if args.fit_previews and args.face and args.allow_extend:
        while any(p["face_fully_visible"] is False for p in result["previews"]) and args.zoom > 0.35:
            args.zoom = round(args.zoom * 0.9, 3)
            result = make(arr, name, preset, args, th, args.out, stem)
        result["zoom"] = args.zoom
    args.zoom = base
    return result


def decision(results, args):
    levels = [c["result"] for r in results for c in r["checks"]]
    if args.erase_results and any(e["background_std"] > args.thresholds["edge_uniform_std"] for e in args.erase_results):
        levels.append("fail")
    if not args.source_approved:
        levels.append("fail")
    if not args.alt:
        levels.append("warn")
    if "fail" in levels:
        return "NOT READY"
    if "warn" in levels:
        return "READY WITH WARNINGS"
    return "READY"


def report_md(results, args, src_size, verdict):
    actions = []
    if args.erase:
        actions.append("REMOVE EMBEDDED TEXT")
    if args.subject or args.focal:
        actions.append("RECOMPOSE")
    actions.append("RESIZE")
    lines = [
        "## Image assessment",
        f"**Date:** {date.today().isoformat()}",
        f"**Source:** {args.source.name} ({src_size[0]}x{src_size[1]}), "
        + ("authorised source confirmed" if args.source_approved else "**source approval not confirmed**"),
        f"**Image action selected:** {' + '.join(actions)}",
        "**Action actually performed:** Derivatives created; the source file is unchanged.",
        "",
    ]
    if args.erase_results:
        lines.append("**Embedded text removed:**")
        for e in args.erase_results:
            flat = e["background_std"] <= args.thresholds["edge_uniform_std"]
            lines.append(f"- Box {e['box']} filled with RGB{tuple(e['fill_rgb'])} "
                         + ("(flat background, clean result)" if flat else
                            f"(**textured background, std {e['background_std']}: needs manual retouching**)"))
        lines.append("")
    for r in results:
        lines += [
            f"### {r['label']}: `{r['file']}`",
            f"- **Target dimensions:** {r['width']}x{r['height']} ({r['basis']})",
            f"- **Focal point:** {r['focal_point_pct'][0]}% across, {r['focal_point_pct'][1]}% down "
            "(set this in SharePoint: select the image, then *Set focal point*)",
            f"- **Source crop:** {r['source_crop']}, scale {r['scale']:.0%}"
            + (f", background extended {', '.join(f'{k} {v}px' for k, v in r['extended_px'].items() if v)}"
               if any(r['extended_px'].values()) else ""),
            f"- **Preview sheet:** `{r['preview_sheet']}`",
            "",
            "| Check | Result |", "|---|---|",
        ]
        lines += [f"| {c['detail']} | {c['result'].upper()} |" for c in r["checks"]]
        lines.append("")
    lines += [
        f"**Accessibility:** "
        + (f"Alt text: \"{args.alt}\". If the image is decorative beside a page title that already names the person, use empty alt text."
           if args.alt else "**No alt text supplied.** Write alt text describing the picture, or mark it decorative."),
        "Keep any message (for example \"Update from ...\") as page text, not in the image.",
        "**Brand/source check:** The source's branding is preserved and nothing was recreated. "
        "Check against the Hutchison Ports Brand Guidelines before publishing.",
        f"**READY assessment:** {verdict}",
        "**Publication decision:** "
        + {"READY": "Upload the derivative, set the focal point, then preview on desktop and narrow/mobile before publishing.",
           "READY WITH WARNINGS": "Resolve or accept the warnings above, upload the derivative, set the focal point and preview desktop and mobile before publishing.",
           "NOT READY": "Do not publish yet. Fix the failed checks above."}[verdict],
    ]
    return "\n".join(lines)


def main():
    presets_doc = json.loads(PRESETS.read_text())
    presets = presets_doc["presets"]
    th = presets_doc["thresholds"]

    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("source", type=Path)
    ap.add_argument("--preset", action="append", choices=sorted(presets), help="repeatable; default news-banner")
    ap.add_argument("--focal", type=point, help="x,y in source pixels: the point that must stay in view (usually the face)")
    ap.add_argument("--face", type=box, help="x0,y0,x1,y1 of the face/head; checked in every responsive preview")
    ap.add_argument("--subject", type=box, help="x0,y0,x1,y1 of the whole subject; used for headroom and framing")
    ap.add_argument("--erase", type=box, action="append", default=[], help="x0,y0,x1,y1 of embedded text to remove (flat backgrounds only); repeatable")
    ap.add_argument("--allow-extend", action="store_true", help="extend flat background to add headroom or width")
    ap.add_argument("--headroom", type=float, default=th["headroom"], help="space above subject as a fraction of height")
    ap.add_argument("--zoom", type=float, default=1.0, help=">1 crops tighter around the focal point; <1 zooms out (needs --allow-extend)")
    ap.add_argument("--fit-previews", action="store_true",
                    help="zoom out (extending the background) until the face fits every responsive preview; needs --face and --allow-extend")
    ap.add_argument("--format", choices=["jpg", "png"], default="jpg")
    ap.add_argument("--alt", help="alt text to record in the report")
    ap.add_argument("--source-approved", action="store_true", help="the source is an authorised HPUK image")
    ap.add_argument("--out", type=Path, default=Path("out"))
    ap.add_argument("--check-boxes", action="store_true",
                    help="only draw the focal point and boxes on a copy of the source, to check coordinates before rendering")
    args = ap.parse_args()
    args.thresholds = th

    if not args.source.is_file():
        sys.exit(f"Source not found: {args.source}")
    # Derivative names always add a preset suffix, so the source is never overwritten.
    args.out.mkdir(parents=True, exist_ok=True)

    src = ImageOps.exif_transpose(Image.open(args.source)).convert("RGB")
    if args.check_boxes:
        overlay = src.copy()
        d = ImageDraw.Draw(overlay)
        for b in args.erase:
            d.rectangle(b, outline="#ff3b30", width=4)
        if args.subject:
            d.rectangle(args.subject, outline="#34c759", width=4)
        if args.face:
            d.rectangle(args.face, outline="#ffcc00", width=4)
        if args.focal:
            fx, fy = args.focal
            d.ellipse((fx - 10, fy - 10, fx + 10, fy + 10), fill="#ff3b30")
        path = args.out / f"{args.source.stem}_boxes.png"
        overlay.save(path)
        print(f"Source {src.size[0]}x{src.size[1]}. Red = erase, green = subject, yellow = face, dot = focal point: {path}")
        return 0
    arr = np.array(src)
    args.erase_results = [erase(arr, b) for b in args.erase]

    stem = args.source.stem
    results = [fit(arr, n, presets[n], args, th, stem) for n in (args.preset or ["news-banner"])]
    verdict = decision(results, args)
    md = report_md(results, args, src.size, verdict)

    (args.out / f"{stem}_report.md").write_text(md + "\n")
    (args.out / f"{stem}_report.json").write_text(json.dumps(
        {"source": str(args.source), "source_size": src.size, "verdict": verdict,
         "erased": args.erase_results, "alt": args.alt, "results": results}, indent=2))
    print(md)
    print(f"\nFiles written to {args.out.resolve()}")
    return 0 if verdict != "NOT READY" else 2


if __name__ == "__main__":
    sys.exit(main())

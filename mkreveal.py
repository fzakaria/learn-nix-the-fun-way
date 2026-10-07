#!/usr/bin/env python3
"""Assemble a reveal.js deck from Typst's per-page SVG export.

Typst has no HTML slide output, and Touying's official HTML path
(touying-exporter) is a pip install that would break the hermetic build. But
Typst *does* export one SVG per page, and the pdfpc sidecar already carries the
speaker notes -- which is everything reveal.js needs.

So: one <section> per page, the SVG as a contained background image, and the
note in an <aside class="notes">. That buys reveal's speaker view (press S:
notes, next slide, and a timer on a second screen), overview mode, keyboard and
touch navigation, and deep links -- in a browser.

A background image is not clickable, so each <a> Typst wrote into a slide's
SVG -- a translate() plus a transparent rect -- is mirrored as a transparent
HTML link laid over the same spot, in percent of the viewBox. Every link in the
deck works in the browser, and keyboard navigation is untouched.

A background image does not animate either: the browser draws an SVG used as
an image as one static frame, embedded GIFs included. So theme.typ marks each
GIF with an `anim:<path>` link (reveal build only), and that box gets the real
GIF as an <img> on top, copied into the site under anim/.

The slides stay vector, so they are sharp at any projector resolution.

  python mkreveal.py --svg-dir slides --pdfpc deck.pdfpc --out site
"""
from __future__ import annotations

import argparse
import html
import json
import pathlib
import re
import shutil

TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<link rel="stylesheet" href="dist/reset.css">
<link rel="stylesheet" href="dist/reveal.css">
<link rel="stylesheet" href="dist/theme/white.css">
<style>
  /* The SVG already carries the slide's own background and margins, so strip
     reveal's: no padding, no drop shadow, no text styling to inherit. */
  :root {{ --r-background-color: {bg}; }}
  .reveal .slides section {{ padding: 0; height: 100%; }}
  .reveal a.hit {{ position: absolute; display: block; }}
  .reveal img.anim {{ position: absolute; margin: 0; max-width: none;
                      max-height: none; border: 0; box-shadow: none; }}
  .reveal .slide-background {{ background-color: {bg}; }}
</style>
</head>
<body>
<div class="reveal">
  <div class="slides">
{sections}
  </div>
</div>
<script src="dist/reveal.js"></script>
<script src="plugin/notes/notes.js"></script>
<script>
  Reveal.initialize({{
    // Match the Typst page so the vector slides land pixel-exact.
    width: {width}, height: {height},
    margin: 0,
    center: false,       // sections fill the slide, so link overlays line up
    hash: true,          // deep-link to a slide
    slideNumber: 'c/t',
    transition: 'none',  // a fade between full-page images just looks like lag
    plugins: [ RevealNotes ],
  }});
</script>
</body>
</html>
"""

SECTION = """    <section data-background-image="{svg}"
             data-background-size="contain"
             data-background-color="{bg}">{links}{notes}
    </section>"""

VIEWBOX = re.compile(r'<svg[^>]*viewBox="0 0 ([\d.]+) ([\d.]+)"')
LINK = re.compile(
    r'<a transform="translate\(([\d.-]+) ([\d.-]+)\)" href="([^"]+)"[^>]*>'
    r'<rect width="([\d.]+)" height="([\d.]+)"')


def overlays(svg_text: str, anims: dict[str, str]) -> str:
    """HTML links mirroring the SVG's own, positioned in % of the page.

    An `anim:<path>` link is a GIF to animate rather than a link: it becomes
    an <img>, and `anims` collects source path -> site path for copying.
    """
    vb = VIEWBOX.search(svg_text)
    if not vb:
        return ""
    vw, vh = float(vb[1]), float(vb[2])
    out = []
    for x, y, href, w, h in LINK.findall(svg_text):
        x, y, w, h = map(float, (x, y, w, h))
        box = (f'left:{x / vw:.3%};top:{y / vh:.3%};'
               f'width:{w / vw:.3%};height:{h / vh:.3%}')
        if href.startswith("anim:"):
            src = html.unescape(href[len("anim:"):])
            anims[src] = "anim/" + pathlib.Path(src).name
            out.append(f'\n      <img class="anim" src="{html.escape(anims[src])}"'
                       f' alt="" style="{box}">')
        else:
            out.append(
                f'\n      <a class="hit" href="{html.escape(href)}" target="_blank"'
                f' rel="noopener" style="{box}"></a>')
    return "".join(out)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--svg-dir", required=True, help="directory of slide-NN.svg")
    ap.add_argument("--pdfpc", required=True, help="pdfpc sidecar with the notes")
    ap.add_argument("--reveal", help="reveal.js source tree to copy dist/ and plugin/ from")
    ap.add_argument("--out", required=True)
    ap.add_argument("--root", default=".", help="where `anim:` paths are relative to")
    ap.add_argument("--title", default="Learn Nix the Fun Way")
    ap.add_argument("--bg", default="#fcfcfb")
    ap.add_argument("--width", type=int, default=1600)
    ap.add_argument("--height", type=int, default=900)
    args = ap.parse_args()

    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    svgs = sorted(pathlib.Path(args.svg_dir).glob("*.svg"))
    if not svgs:
        raise SystemExit(f"no SVGs in {args.svg_dir}")

    # pdfpc indexes pages from 0 and omits `note` for pages that have none.
    notes = {
        p["idx"]: p.get("note", "")
        for p in json.loads(pathlib.Path(args.pdfpc).read_text())["pages"]
    }

    (out / "slides").mkdir(exist_ok=True)
    sections = []
    anims: dict[str, str] = {}
    for i, svg in enumerate(svgs):
        shutil.copy2(svg, out / "slides" / svg.name)
        note = notes.get(i, "")
        aside = ""
        if note.strip():
            # Blank lines are the paragraph breaks that make a note skimmable
            # at a glance, which is the whole point of the speaker view.
            # Within a paragraph, a `- ` line is a bullet and keeps its own
            # line; any other newline is source wrapping and HTML reflows it.
            paras = "".join(
                "<p>" + html.escape(p.strip()).replace("\n- ", "<br>- ") + "</p>"
                for p in note.split("\n\n") if p.strip()
            )
            aside = f'\n      <aside class="notes">{paras}</aside>'
        sections.append(SECTION.format(
            svg=f"slides/{svg.name}", bg=args.bg,
            links=overlays(svg.read_text(), anims), notes=aside))

    for src, dst in anims.items():
        (out / dst).parent.mkdir(exist_ok=True)
        shutil.copy2(pathlib.Path(args.root) / src, out / dst)

    if args.reveal:
        src = pathlib.Path(args.reveal)
        for sub in ("dist", "plugin"):
            shutil.copytree(src / sub, out / sub, dirs_exist_ok=True)

    (out / "index.html").write_text(TEMPLATE.format(
        title=html.escape(args.title), bg=args.bg,
        width=args.width, height=args.height,
        sections="\n".join(sections),
    ))
    print(f"wrote {out}/index.html  ({len(svgs)} slides, "
          f"{sum(1 for i in range(len(svgs)) if notes.get(i, '').strip())} with notes, "
          f"{len(anims)} animated GIFs)")


if __name__ == "__main__":
    main()

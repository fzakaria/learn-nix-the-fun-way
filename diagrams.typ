// Diagrams drawn natively rather than pasted in as screenshots: they stay
// sharp at any zoom, their text is selectable, and they pick up the deck's
// fonts and palette. Each one redraws a figure from an earlier version of the
// talk; where the original is someone else's, the slide credits it.
//
// Everything here is placed on an explicit grid of points, so there is no
// layout to fight -- but also no reflow: change a label's length and check
// the arrows still land.

#let palette = toml("palette.toml")
#let ink = rgb(palette.ink.primary)
#let ink2 = rgb(palette.ink.secondary)
#let muted = rgb(palette.ink.muted)
#let faint = rgb(palette.surface.baseline)
#let panel = rgb(palette.surface.panel)
#let blue = rgb(palette.series.one)
#let orange = rgb(palette.series.two)
#let sans = palette.font.sans
#let mono = palette.font.mono

/// A small filled arrowhead with its tip at `(x, y)`, pointing `dir`
/// (`left`, `right` or `down`).
#let _head(x, y, dir: left, fill: ink, s: 5pt) = {
  let pts = if dir == left { ((0pt, s / 2), (s, 0pt), (s, s)) }
    else if dir == right { ((s, s / 2), (0pt, 0pt), (0pt, s)) }
    else { ((s / 2, s), (0pt, 0pt), (s, 0pt)) }
  let (dx, dy) = if dir == left { (x, y - s / 2) }
    else if dir == right { (x - s, y - s / 2) }
    else { (x - s / 2, y - s) }
  place(top + left, dx: dx, dy: dy, polygon(fill: fill, ..pts))
}

// ---------------------------------------------------------------------------
// The Nix store, after Figure 2.x of Eelco Dolstra's thesis: store entries as
// a tree, with every file-level reference drawn as an arc. The point is that
// references only ever land on other store paths.
// ---------------------------------------------------------------------------

// (depth, label). Package rows are depth 1.
#let _store-rows = (
  (0, "/nix/store"),
  (1, "bwacc7a5c5n3…-hello-2.1.1"),
  (2, "bin"), (3, "hello"), (2, "man"), (3, "man1"), (4, "hello1"),
  (1, "72by2iw5wd8i…-glibc-2.3.5"),
  (2, "lib"), (3, "libc.so.6"),
  (1, "v2cc475f6nv1…-subversion-1.1.4"),
  (2, "bin"), (3, "svn"), (2, "lib"), (3, "libsvn…so"),
  (1, "5jq6jgkamxjj…-openssl-0.9.7d"),
  (2, "lib"), (3, "libssl.so.0.9.7"),
  (1, "h7yw7a257m1i…-db4-4.3.28"),
  (2, "lib"), (3, "libdb-4.so"),
  (1, "dg7c6zr5vqrj…-subversion-1.2.0"),
  (2, "bin"), (3, "svn"), (2, "lib"), (3, "libsvn…so"),
  (1, "8ggmblhvzciv…-openssl-0.9.7f"),
  (2, "lib"), (3, "libssl.so.0.9.7"),
)

// (from row, to row): hello -> man page, hello -> libc, and so on.
#let _store-refs = (
  (3, 5), (3, 9),
  (12, 14), (14, 9), (14, 17), (14, 20),
  (23, 25), (25, 20), (25, 28),
)

/// The store as a tree with its references. Rows in `closure` (a range) are
/// drawn in bold and everything else greyed: pass the rows of one package's
/// closure to show that it is self-contained.
#let store-tree(closure: none, lh: 12.5pt, size: 9pt, indent: 13pt) = context {
  let rows = _store-rows
  let in-closure(i) = closure == none or i == 0 or i in closure
  let colour(i) = if in-closure(i) { ink } else { faint }
  let label(i) = text(
    size: size, font: sans, fill: colour(i),
    weight: if closure != none and in-closure(i) and i != 0 { "bold" } else { "regular" },
    rows.at(i).at(1),
  )
  let x(i) = rows.at(i).at(0) * indent
  let y(i) = i * lh + lh / 2
  let end(i) = x(i) + measure(label(i)).width + 2pt
  let width = calc.max(..range(rows.len()).map(end)) + 70pt

  box(width: width, height: rows.len() * lh, {
    for (i, (depth, _)) in rows.enumerate() {
      place(top + left, dx: x(i), dy: i * lh, box(height: lh, align(horizon, label(i))))
      if depth > 0 {
        // Elbow from the parent's spine to this row.
        let p = range(i).rev().find(j => rows.at(j).at(0) == depth - 1)
        let sx = x(p) + 3pt
        let st = (stroke: 0.8pt + colour(i))
        place(top + left, line(start: (sx, y(p) + lh / 2 - 1pt), end: (sx, y(i)), ..st))
        place(top + left, line(start: (sx, y(i)), end: (x(i) - 2pt, y(i)), ..st))
      }
    }
    for (a, b) in _store-refs {
      let fill = if in-closure(a) and in-closure(b) { ink } else { faint }
      let (x1, y1, x2, y2) = (end(a), y(a), end(b) + 6pt, y(b))
      let bulge = calc.max(x1, x2) + 14pt + calc.abs(b - a) * 3pt
      place(top + left, curve(
        stroke: 0.8pt + fill,
        curve.move((x1, y1)),
        curve.cubic((bulge, y1), (bulge, y2), (x2, y2)),
      ))
      _head(x2 - 5pt, y2, fill: fill)
    }
  })
}

// ---------------------------------------------------------------------------
// ELF file layout, after Surueña's diagram (CC BY-SA 3.0): the program header
// table points at segments, the section header table at sections.
// ---------------------------------------------------------------------------

#let elf-layout(w: 6.2cm, rh: 1.05cm) = {
  // (label, height in rows)
  let parts = (
    ("ELF header", 0.8), ("Program header table", 0.8), (".text", 1.4),
    (".rodata", 1.0), ("…", 0.6), (".data", 1.0), ("Section header table", 0.8),
  )
  let tops = parts.fold((0,), (acc, p) => acc + (acc.last() + p.at(1),))
  let mid(i) = (tops.at(i) + parts.at(i).at(1) / 2) * rh
  let gutter = 1.4cm
  box(width: w + 2 * gutter, height: tops.last() * rh, {
    for (i, (name, hh)) in parts.enumerate() {
      let dashed = name == "…"
      place(top + left, dx: gutter, dy: tops.at(i) * rh, rect(
        width: w, height: hh * rh,
        stroke: if dashed { none } else { 0.8pt + ink },
        fill: if dashed { none } else { white },
        align(center + horizon, text(size: 0.5em, name)),
      ))
    }
    // Program header table -> segments, on the left.
    let ph = mid(1)
    for t in (2, 5) {
      let ty = mid(t)
      place(top + left, curve(stroke: 0.9pt + blue,
        curve.move((gutter, ph)),
        curve.cubic((gutter * 0.1, ph), (gutter * 0.1, ty), (gutter - 6pt, ty)),
      ))
      _head(gutter, ty, dir: right, fill: blue)
    }
    // Section header table -> sections, on the right.
    let sh = mid(6)
    let r = gutter + w
    for t in (2, 3, 5) {
      let ty = mid(t)
      let reach = 0.25 + (6 - t) * 0.12
      place(top + left, curve(stroke: 0.9pt + orange,
        curve.move((r, sh)),
        curve.cubic((r + gutter * reach * 2, sh), (r + gutter * reach * 2, ty), (r + 6pt, ty)),
      ))
      _head(r, ty, fill: orange)
    }
  })
}

// ---------------------------------------------------------------------------
// The declarative trinity, after Understand NixOS: Nix is each of the three,
// and none of the three is another.
// ---------------------------------------------------------------------------

#let trinity(s: 11cm) = {
  let dark = rgb("#3b3b3b")
  let red = rgb("#c8502b")
  let top-pt = (s / 2, 0.11 * s)
  let left-pt = (0.11 * s, 0.86 * s)
  let right-pt = (0.89 * s, 0.86 * s)
  let centre = (s / 2, 0.61 * s)
  let bar(a, b, colour, label, width: 0.07 * s) = {
    place(top + left, line(start: a, end: b, stroke: (paint: colour, thickness: width, cap: "butt")))
    let (ax, ay) = a
    let (bx, by) = b
    let angle = calc.atan2((bx - ax) / 1pt, (by - ay) / 1pt)
    // Keep the label upright-ish: never upside down.
    if angle > 90deg { angle -= 180deg } else if angle < -90deg { angle += 180deg }
    let m = ((ax + bx) / 2, (ay + by) / 2)
    place(top + left, dx: m.at(0), dy: m.at(1),
      place(center + horizon, rotate(angle, reflow: true,
        text(size: 0.032 * s, fill: white, weight: "bold", tracking: 0.08em, label))))
  }
  let node(p, label, r: 0.105 * s, size: 0.026 * s) = place(top + left,
    dx: p.at(0) - r, dy: p.at(1) - r,
    circle(radius: r, fill: white, stroke: (0.025 * s) + dark,
      align(center + horizon, text(size: size, fill: red, weight: "bold", font: "DejaVu Serif", label))))
  box(width: s, height: 0.98 * s, {
    bar(top-pt, left-pt, dark, "IS NOT")
    bar(top-pt, right-pt, dark, "IS NOT")
    bar(left-pt, right-pt, dark, "IS NOT")
    bar(centre, top-pt, red, "IS", width: 0.055 * s)
    bar(centre, left-pt, red, "IS", width: 0.055 * s)
    bar(centre, right-pt, red, "IS", width: 0.055 * s)
    node(top-pt, [The \ Operating \ System])
    node(left-pt, [The \ Package \ Manager])
    node(right-pt, [The \ Language])
    node(centre, text(size: 0.11 * s, fill: dark)[Nix], r: 0.13 * s)
  })
}

// ---------------------------------------------------------------------------
// neofetch on NixOS: the logo (six lambdas) beside the system summary.
// ---------------------------------------------------------------------------

/// The NixOS snowflake: six lambdas, alternating two blues, each turned 60°
/// from the last so the long legs ring a hexagonal hole.
#let snowflake(r: 2.4cm) = box(width: 2 * r, height: 2 * r, {
  let u = r / 12
  // One λ in units of `u`: the long leg runs down-right at 60°, the short
  // leg branches off it down-left. Offset so the six interlock.
  let (tx, ty) = (-4.4, -9.8)
  let lambda = (
    (0, 0), (2, 0), (6, 6.93), (4, 6.93), (2.85, 4.94), (1.7, 6.93),
    (-0.3, 6.93), (1.85, 3.2),
  ).map(((a, b)) => ((a + tx) * u, (b + ty) * u))
  for k in range(6) {
    let fill = if calc.even(k) { rgb("#7ebae4") } else { rgb("#5277c3") }
    place(top + left, dx: r, dy: r,
      rotate(k * 60deg, origin: top + left, reflow: false,
        place(top + left, polygon(fill: fill, ..lambda))))
  }
})

#let neofetch = {
  let key = rgb("#7ebae4")
  let val = rgb("#e6e6e6")
  let kv(k, v) = [#text(fill: key, k): #text(fill: val, v)]
  block(fill: rgb("#16181d"), inset: 0.9em, radius: 8pt, align(left, text(font: mono, size: 0.47em, fill: val, {
    text(fill: rgb("#a6d189"))[eudoxia\@sextant]
    [:\~\$ neofetch]
    v(0.4em)
    grid(
      columns: 2, column-gutter: 2.5em, align: horizon,
      snowflake(),
      {
        set par(leading: 0.32em, spacing: 0.32em)
        text(fill: key)[eudoxia\@sextant] + linebreak()
        [---------------] + linebreak()
        (
          kv("OS", "NixOS 22.11.3681.2b1bba76a13 (Raccoon) x86_64"),
          kv("Host", "LENOVO 20Y5002MAU"),
          kv("Kernel", "5.15.106"),
          kv("Uptime", "2 hours, 7 mins"),
          kv("Packages", "934 (nix-system), 1431 (nix-user)"),
          kv("Shell", "bash 5.1.16"),
          kv("Resolution", "2560x1600"),
          kv("DE", "none+spectrum"),
          kv("WM", "spectrum"),
          kv("Theme", "Adwaita [GTK3]"),
          kv("Icons", "Adwaita [GTK3]"),
          kv("Terminal", "urxvt"),
          kv("Terminal Font", "terminus"),
          kv("CPU", "11th Gen Intel i7-11800H (16) @ 4.600GHz"),
          kv("GPU", "NVIDIA GeForce RTX 3050 Ti Mobile"),
          kv("GPU", "Intel TigerLake-H GT1 [UHD Graphics]"),
          kv("Memory", "3218MiB / 15727MiB"),
        ).join(linebreak())
        v(0.25em)
        for c in ("#4d4d4d", "#b04a4a", "#8fa65a", "#f2c27a", "#6a9fb5", "#ad7fa8", "#7ebcb0", "#d9d9d9") {
          box(width: 1.4em, height: 1em, fill: rgb(c))
        }
      },
    )
  })))
}

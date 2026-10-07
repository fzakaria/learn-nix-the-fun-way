// Deck theme: a thin layer over Touying's `simple`, tuned for one
// headline + one visual (or one terminal) per slide.
//
// Colour comes from palette.toml, so slide chrome and every helper below
// draw from the same handful of values.

#import "@preview/touying:0.8.0": *
#import "@preview/touying:0.8.0": speaker-note as touying-speaker-note
#import themes.simple: *

#let palette = toml("palette.toml")

#let ink      = rgb(palette.ink.primary)
#let ink2     = rgb(palette.ink.secondary)
#let muted    = rgb(palette.ink.muted)
#let surface  = rgb(palette.surface.page)
#let blue     = rgb(palette.series.one)
#let orange   = rgb(palette.series.two)
#let green    = rgb(palette.series.three)
#let critical = rgb(palette.status.critical)
#let sans     = palette.font.sans
#let mono     = palette.font.mono

/// Where speaker notes go, chosen at compile time so one source produces
/// every variant:
///
///   typst compile deck.typ                         slides only
///   typst compile --input notes=right deck.typ     presenter: slide | notes
///   typst compile --input notes=only  deck.typ     notes only
///
/// Touying also reads `--input export-mode=article`, but we do not build it:
/// under the `simple` theme it breaks a page at every heading, so the deck
/// comes out at double length with every other page blank.
///
/// The pdfpc sidecar is emitted regardless; it is metadata, not layout.
#let _notes = sys.inputs.at("notes", default: "none")

/// Provenance, passed in by flake.nix as `--input`s. A `just watch` build
/// has none of them, and says so.
#let _repo = sys.inputs.at("repo", default: "github.com/fzakaria/learn-nix-the-fun-way")
#let _rev  = sys.inputs.at("rev", default: "dev")
#let _src  = sys.inputs.at("src", default: none)

/// Repo, commit and source store path: the slide footer, and the lines
/// under the title. Fittingly for this talk, the store path is enough to
/// rebuild the deck bit-for-bit with `nix build <path>#site`.
///
/// Each piece is an unbreakable box: the whole line is too long to promise
/// it fits, and a store path broken across two lines is worse than useless.
/// The footer drops the `github.com/` (the link still has it) so that, with
/// the slide counter beside it, it stays on one line.
#let _piece(body) = box(body)
#let _repo-link(full) = _piece(link("https://" + _repo,
  if full { _repo } else { _repo.trim("github.com/", at: start) }))
#let _rev-link = _piece(link("https://" + _repo + "/commit/" + _rev, _rev))
#let _src-text = if _src != none { _piece(_src) }

/// Footer: `owner/repo@rev · /nix/store/…-source`, on one line.
#let provenance = text(size: 0.75em, fill: muted, font: mono, {
  _repo-link(false)
  [\@]
  _rev-link
  if _src != none [ #sym.dot.c #_src-text]
})

/// Title slide: repo and commit, then the store path on a line of its own.
#let provenance-block = text(size: 0.6em, fill: muted, font: mono, {
  _repo-link(true)
  [ #sym.dot.c ]
  _rev-link
  if _src != none { linebreak(); _src-text }
})

/// Speaker notes are written as plain strings wrapped at ~88 columns in the
/// source, and every consumer -- the PDF notes pane, the pdfpc sidecar,
/// reveal's speaker view (`white-space: pre-wrap`) -- would otherwise keep
/// each source newline as a hard break. So reflow the string once, here: a
/// blank line is a paragraph, a line starting `- ` is a bullet, and any other
/// newline is just a space.
#let _reflow(txt) = {
  txt
  .split("\n\n")
  .filter(p => p.trim() != "")
  .map(para => {
    let out = ()
    for line in para.split("\n").map(l => l.trim()) {
      if out.len() == 0 or line.starts-with("- ") { out.push(line) } else {
        out.at(-1) = out.at(-1) + " " + line
      }
    }
    out.join("\n")
  })
  .join("\n\n")
}

/// Touying's `speaker-note`, fed the reflowed string. deck.typ imports this
/// after Touying, so it shadows the original.
///
/// `subslide: none` shows the note on every click of its slide. Touying's
/// default ties a note to the `#pause` it follows, and the note sits at the
/// end of the slide -- so the first clicks of a slide would have none.
#let speaker-note(note, subslide: none, ..args) = touying-speaker-note(
  if type(note) == str { _reflow(note) } else { note },
  subslide: subslide,
  ..args,
)

/// The note as pane content: paragraphs and bullet lines from the string.
#let _note-content(note) = if type(note) != str { note } else {
  note.split("\n\n").map(p => p.split("\n").join(linebreak())).join(parbreak())
}

/// The notes pane, for the presenter (`notes=right`) and notes-only builds.
///
/// Replaces Touying's default, which sets every note at a fixed 24pt and
/// silently clips whatever runs past the bottom of the page. Here the note is
/// measured and set at the largest size that fits. In notes-only mode the
/// slide preview sits beside the headline rather than on top of the text.
///
/// The `note` Touying passes is an opaque `context` element, so the raw string
/// is read from its state instead; that is what lets `_reflow` see the text.
#let _notes-pane(self: none, note: none, slide-preview: none) = block(
  width: 100%, height: 100%, fill: rgb(palette.surface.panel), inset: 28pt,
  layout(size => {
    set align(left + top)
    set par(spacing: 0.9em)
    let head = grid(
      columns: (1fr, auto), column-gutter: 16pt,
      text(size: 20pt, weight: "bold", fill: ink,
        utils.display-current-heading(level: 2)),
      if slide-preview != none {
        box(stroke: muted + 0.5pt, scale(25%, reflow: true, slide-preview))
      },
    )
    let room = size.height - measure(head, width: size.width).height - 16pt
    head
    v(16pt)
    // Read the note *after* the header: in notes-only mode the preview in
    // the header is what sets the state, so reading any earlier finds none.
    context {
      let body = _note-content(utils.slide-note-state.get())
      let fit = 20
      while fit > 8 and measure(
        block(width: size.width, text(size: fit * 1pt, fill: ink, body)),
      ).height > room { fit -= 1 }
      text(size: fit * 1pt, fill: ink, body)
    }
  }),
)

/// A shell prompt at the start of a `console` line, and a line that is just
/// a context marker such as `[nix-shell]`. See `deck-theme`.
#let _prompt = regex("^(\\[[^\\]]*\\]\\$ |> |\\$ )")
#let _context = regex("^\\[[^\\]]*\\]$")

/// The show-rule every deck applies once at the top.
#let deck-theme(body) = {
  show: simple-theme.with(
    aspect-ratio: "16-9",
    primary: blue,
    footer: provenance,
    // `simple` sets a 2em margin all round with the footer at the very top
    // of the bottom margin (`footer-descent: 0em`), i.e. touching whatever
    // ends the slide. A deeper bottom margin, with the footer dropped into
    // it, keeps a clear gap. (A `set page(margin: ..)` would do nothing:
    // Touying builds each page from this config, not from set rules.)
    config-page(margin: (x: 2em, top: 2em, bottom: 3em), footer-descent: 1.1em),
    config-common(
      show-notes-on-second-screen: if _notes in ("left", "right", "top", "bottom") {
        // `right` etc. are alignment values, not strings.
        if _notes == "right" { right }
        else if _notes == "left" { left }
        else if _notes == "top" { top }
        else { bottom }
      } else { none },
      show-only-notes: _notes == "only",
      notes-fn: _notes-pane,
    ),
    // `simple` repeats the level-1 heading as a running header. There are no
    // level-1 headings here -- each slide is a level-2 `==` -- so drop it and
    // give the space to the visual.
    header: none,
    // This is what actually renders the `==` headline. Setting it to `none`
    // silently deletes every slide title, which is not obvious from the name.
    subslide-preamble: block(
      below: 0.5em,
      align(left, text(size: 0.95em, weight: "bold", fill: ink,
        utils.display-current-heading(level: 2))),
    ),
  )

  set page(fill: surface)

  // Emoji in colour. Typst takes each glyph from the first font that has it,
  // and DejaVu Sans carries its own black-and-white ✔, 😎, 😔 and friends --
  // so with Noto Color Emoji merely next in line, those come out as outlines.
  // Send pictographs (and the variation selector that asks for colour)
  // straight to Noto. ©, ® and ™ are pictographs too, but should stay text.
  show regex("[\\p{Extended_Pictographic}&&[^\\u{00A9}\\u{00AE}\\u{2122}]]\\u{FE0F}?"): set text(font: "Noto Color Emoji")
  set text(fill: ink, size: 24pt, font: sans)
  // Typst sets raw text at 0.8em, which makes an inline store path look
  // visibly smaller than the sentence around it. This compounds with that
  // built-in 0.8 to 0.88em: DejaVu Sans Mono runs taller than DejaVu Sans at
  // the same size, so 0.88em is where the two look alike. Code panels fit
  // their own size anyway (see `_panel`).
  show raw: set text(font: mono, size: 1.1em)

  // Terminal sessions. Typst's highlighter has no `console` language, and
  // `bash` would read the `> ` prompt as a redirect. So split each line: a
  // prompt (`> `, `$ `, `[alice@nixos:~]$ `) is muted and the command after
  // it highlighted as bash; any other line is output, in a softer ink, so
  // commands and their results read apart at a glance. Bare fenced blocks
  // with no language are output too (the later steps of a terminal).
  //
  // Each piece is itself `raw`, so it gets the same font as any other code.
  // But raw inside raw is scaled twice (see the size rule above), so undo
  // one 0.88 first. A line after one ending in `\` continues the command.
  show raw.where(lang: "console"): it => {
    set text(size: 1em / 0.88)
    let out = ()
    let continued = false
    for line in it.text.split("\n") {
      let m = line.match(_prompt)
      out.push(if m != none {
        // Run a store path and bash colours the whole path as the command
        // name; colour just the program at the end, like `nix` or `cat`.
        let cmd = line.slice(m.end)
        let word = cmd.split(" ").first()
        let dir = if word.starts-with("/") and word.contains("/") {
          word.slice(0, word.len() - word.split("/").last().len())
        } else { "" }
        text(fill: muted, raw(m.text)) + raw(dir) + raw(cmd.slice(dir.len()), lang: "bash")
      } else if continued {
        raw(line, lang: "bash")
      } else if line.match(_context) != none {
        text(fill: muted, raw(line))
      } else {
        text(fill: ink2, raw(line))
      })
      continued = (m != none or continued) and line.ends-with("\\")
    }
    out.join(linebreak())
  }
  show raw.where(block: true, lang: none): set text(fill: ink2)

  // Anything clickable should look it. `anim:` links are not links -- they
  // mark GIFs for the reveal build (see `visual`) -- so leave those alone.
  show link: it => {
    if type(it.dest) == str and it.dest.starts-with("anim:") { it }
    else { underline(offset: 2pt, text(fill: blue, it)) }
  }

  body
}

/// Where a slide's single visual sits: centred in the space below the
/// headline.
#let _place = center + horizon

/// Set by the reveal.js build only. See `visual`.
#let _anim = sys.inputs.at("anim", default: none) != none

/// One visual, centred, filling the space under the headline.
///
/// Sized by height so wide diagrams and tall memes land in the same optical
/// box. Override with `h:` for the occasional outlier.
///
/// A GIF only ever shows its first frame on a slide: a PDF cannot animate,
/// and the reveal.js build shows each slide as an SVG background, which
/// browsers draw as a static picture. So for the reveal build (`--input
/// anim=1`) a GIF is wrapped in an `anim:` link -- Typst writes the link's
/// box into the SVG -- and mkreveal.py lays the real, animated GIF over
/// exactly that box. The PDFs never see the link.
#let visual(path, h: 88%) = align(_place, {
  let img = image(path, height: h)
  if _anim and path.ends-with(".gif") { link("anim:" + path, img) } else { img }
})

/// The gap between lines of code. See `_panel` and `code`.
///
/// Roomy by default, which suits a short terminal. A long listing is
/// limited by its height, so every bit of gap costs font size: tighten it
/// per slide with `leading:` (and give it more of the slide with `height:`).
#let _leading = 0.55em

/// The panel every listing sits in, with its text fitted to the room.
///
/// By default the text is set at the largest size, up to `max`, at which the
/// longest line fits without wrapping and the block fits in `height` of the
/// space below the headline. Store paths are long and a wrapped one is
/// unreadable, so this beats hand-tuning a size per slide. `size:` pins it.
///
/// `fit-to` is what gets measured, `body` what gets shown. They differ while
/// a terminal is filling in: the size is fitted to the finished listing, so
/// it does not change from one click to the next.
#let _panel(body, fit-to: none, size: auto, max: 1.1em, width: 96%, height: 92%,
  leading: _leading,
  grow: true, fill: rgb(palette.surface.panel)) = {
  // `grow`: claim whatever height the slide has left (`1fr`), so the fit is
  // measured against the real room -- after the headline, and after anything
  // else on the slide such as a caption. Without it, `layout` reports the
  // height of the whole slide body and the panel can run off the page.
  // Pass `grow: false` where a panel must not swallow the space, e.g. on a
  // vertically centred slide; `height` is then a share of the whole body.
  let wrap(b) = if grow { block(height: 1fr, width: 100%, b) } else { b }
  wrap(align(_place, layout(region => {
  let inset = 0.9em.to-absolute()
  // The outer `align` centres the block on the slide and would centre its
  // contents too; code must stay flush left or the columns stop lining up.
  //
  // Lines are measured from ascender to descender rather than Typst's
  // default cap-height to baseline, so `_leading` is the true gap between
  // lines -- which is what lets `code` tint adjacent lines as one band.
  let set-in(s, b) = align(left, text(size: s, font: mono, {
    set text(top-edge: "ascender", bottom-edge: "descender")
    set par(leading: leading)
    b
  }))
  let fit = size
  if fit == auto {
    let room-w = region.width * (width / 100%) - 2 * inset
    let room-h = region.height * (height / 100%) - 2 * inset
    let probe = if fit-to == none { body } else { fit-to }
    fit = max
    while fit > 0.3em {
      let m = measure(set-in(fit, probe))
      if m.width <= room-w and m.height <= room-h { break }
      fit -= 0.02em
    }
  }
  block(fill: fill, inset: inset, radius: 8pt, width: width, set-in(fit, body))
})))
}

/// A code block, set natively rather than pasted as a screenshot.
///
/// Typst sets real text here: it stays sharp at any zoom, is selectable in
/// the PDF -- so the store paths can be copied off the slide -- and picks up
/// the deck's mono font.
///
/// Each trailing content block is one click, so a terminal fills in a step
/// at a time -- Slidev's magic-move, minus the motion:
///
///   #codeblock[```console
///   > nix build ...
///   ```][```
///   /nix/store/...
///   ```]
///
/// Not-yet-shown steps keep their space, so nothing jumps. This is done here
/// rather than with `#pause` because Touying cannot see a `#pause` inside
/// the `layout` that the fitting needs; instead the wrapper hands us the
/// current subslide and we hide the later steps ourselves.
#let _codeblock(self: none, steps, opts) = {
  // A clear gap between steps: each is usually a command and its output,
  // and the next command should read as a new thought. A long session can
  // ask for less (`gap:`), since every gap costs it font size.
  let opts = opts
  let gap = v(opts.remove("gap", default: 1.1em))
  let shown = steps.enumerate().map(((i, st)) => if i < self.subslide { st } else { hide(st) })
  _panel(shown.join(gap), fit-to: steps.join(gap), ..opts)
}
#let codeblock(..args) = touying-fn-wrapper(
  _codeblock,
  last-subslide: args.pos().len(),
  args.pos(),
  args.named(),
)

/// A code block with some lines picked out: those in `hl` get a tint, the
/// rest are dimmed. An empty `hl` shows the code plainly. Static: animate it
/// with `stepcode`, or wrap it in `only`.
///
/// Typst has no built-in line highlighting, so this is a show rule on
/// `raw.line`: each picked line gets a tinted box. The box reaches half the
/// line gap up and down, so consecutive picked lines meet and read as one
/// band rather than stripes.
///
/// `src` is a raw block -- write the listing as an ordinary fenced block and
/// its text and language are taken from that -- or a plain string.
#let code(src, lang: "nix", hl: (), leading: _leading, ..opts) = {
  if type(src) == content {
    if src.has("lang") and src.lang != none { lang = src.lang }
    src = src.text
  }
  // Fitted to the bare listing: the full-width highlight box would measure
  // as infinitely wide and shrink the text to nothing.
  _panel(..opts.named(), leading: leading, fit-to: raw(src, lang: lang, block: true), {
    show raw.line: it => {
      if hl.len() == 0 { it }
      else if it.number in hl {
        box(fill: rgb(palette.tint.blue), outset: (y: leading / 2 + 0.01em, x: 0.3em),
          width: 100%, it)
      }
      else { text(fill: muted, it.text) }
    }
    raw(src, lang: lang, block: true)
  })
}

/// Step through highlights of one listing, one click per entry in `steps`
/// -- Slidev's `{all|3,6|all}`. Each step is an array of line numbers; `()`
/// means "everything".
#let _stepcode(self: none, src, steps, opts) = code(
  src, hl: steps.at(calc.min(self.subslide, steps.len()) - 1), ..opts,
)
#let stepcode(src, steps: ((),), ..opts) = touying-fn-wrapper(
  _stepcode,
  last-subslide: steps.len(),
  src, steps, opts.named(),
)

/// Code blocks side by side, each under a caption.
#let codecols(..pairs, size: 0.72em) = align(_place, grid(
  columns: pairs.pos().len(),
  column-gutter: 1.1em,
  ..pairs.pos().map(p => block(
    fill: rgb(palette.surface.panel),
    inset: 0.9em,
    radius: 6pt,
    width: 100%,
    align(left)[
      #text(size: 0.8em, font: mono, weight: "bold", p.at(0))
      #v(0.45em)
      #text(size: size, font: mono, p.at(1))
    ],
  )),
))

/// The hash this whole talk keeps coming back to.
#let hash = "y2g0ijqqiyi9vxr9xgmvvgblxqflqzav"

/// Underline in the deck's green: Slidev's `v-mark.underline.green`.
#let mark(body) = underline(stroke: 3pt + green, offset: 4pt, evade: false, body)

/// The recurring "Remember <hash>" caption under a terminal.
#let remember = align(center, text(size: 0.9em)[Remember #mark(raw(hash))])

/// A slide with no headline: the body centred, the footer kept.
///
/// Touying's own `centered-slide` skips the footer, and a plain `slide`
/// repeats the previous slide's headline (the headline is whatever `==` was
/// last seen). So: a plain `slide` with the headline switched off.
///
/// Slides made by a function call own their body, so a `#speaker-note`
/// written after the call would land on a slide of its own. Pass it as
/// another content block instead: `#bare[Big words][#speaker-note(..)]`.
#let bare(..bodies) = slide(
  config: config-common(subslide-preamble: none),
  setting: body => align(center + horizon, body),
  bodies.pos().join(),
)

/// One large line or two. Anything after the first content block (the
/// notes, usually) is placed as-is, outside the sizing.
#let statement(size: 1.6em, ..bodies) = bare({
  text(size: size, bodies.pos().first())
  bodies.pos().slice(1).join()
})

/// A section divider, in the same colours as everything else.
#let section(title, sub: none, ..rest) = bare({
  text(size: 1.8em, weight: "bold", title)
  if sub != none {
    v(0.1em)
    text(size: 0.9em, fill: ink2, sub)
  }
  rest.pos().join()
})

/// Where a redrawn or borrowed figure came from, bottom right.
#let source(body) = place(bottom + right, dy: -0.2em,
  text(size: 0.45em, fill: muted)[Source: #body])

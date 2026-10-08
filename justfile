# Fast loop. `nix build` is the hermetic path; these share its pins, because
# the dev shell exports the same TYPST_PACKAGE_CACHE_PATH and DECK_FONT_PATH.

default: watch

# live-reload deck.pdf -- millisecond rebuilds
watch:
    typst watch --root . --font-path "$DECK_FONT_PATH" deck.typ deck.pdf

# one-shot compile
build:
    typst compile --root . --font-path "$DECK_FONT_PATH" deck.typ deck.pdf

# every variant, same as `nix build` produces
variants:
    typst compile --root . --font-path "$DECK_FONT_PATH" deck.typ deck.pdf
    typst compile --root . --font-path "$DECK_FONT_PATH" --input notes=right deck.typ deck-presenter.pdf
    typst compile --root . --font-path "$DECK_FONT_PATH" --input handout=1 deck.typ deck-handout.pdf
    typst compile --root . --font-path "$DECK_FONT_PATH" --input handout=1 --input notes=only deck.typ deck-notes.pdf

# slide beside its speaker notes -- open this on your laptop while presenting
presenter:
    typst watch --root . --font-path "$DECK_FONT_PATH" --input notes=right deck.typ deck-presenter.pdf

# speaker notes as pdfpc metadata
notes:
    typst eval --root . --font-path "$DECK_FONT_PATH" \
      'query(<pdfpc-file>).first().value' --in deck.typ > deck.pdfpc

# present with notes on a second screen
present: build notes
    pdfpc deck.pdf

# the deck as a reveal.js site in ./site -- press S for the speaker view
reveal: notes
    mkdir -p svg
    typst compile --format svg --root . --font-path "$DECK_FONT_PATH" --input anim=1 deck.typ 'svg/slide-{0p}.svg'
    python mkreveal.py --svg-dir svg --pdfpc deck.pdfpc --reveal "$REVEAL_SRC" --out site
    @echo "serve it: python -m http.server 8000 --bind :: --directory site"

# read it in a browser, from this machine or a laptop
serve port="8000": variants
    @echo "http://$(hostname -f):{{port}}/"
    python -m http.server {{port}} --bind ::

fmt:
    typstyle -i deck.typ theme.typ

clean:
    rm -rf svg site deck*.pdf deck.pdfpc result

# Learn Nix the Fun Way

[fzakaria.github.io/learn-nix-the-fun-way/](https://fzakaria.github.io/learn-nix-the-fun-way/)

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

A talk on _why you may want to use Nix_: one small script, turned into a
reproducible developer shell, a deployment, a container and a NixOS VM -- then
what Nix actually is, and how it works underneath.

The concept of this talk is based on a similar blog post I had done which you
can find at
[fzakaria.com/2024/07/05/learn-nix-the-fun-way.html](https://fzakaria.com/2024/07/05/learn-nix-the-fun-way.html)

## Build

```bash
nix build              # deck.pdf, deck-presenter.pdf, deck-handout.pdf, deck-notes.pdf, deck.pdfpc
nix build .#site       # the above + a reveal.js version (press S for speaker notes)
nix run                # build and serve at http://localhost:8000/
nix develop            # then `just watch` for live reload
```

The slides are [Typst](https://typst.app) with
[Touying](https://touying-typ.github.io), in `deck.typ`; speaker notes live
beside each slide. Every input is pinned in `flake.nix`, so the build is
reproducible -- which, for this talk in particular, seemed only fair.

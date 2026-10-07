{
  description = "Learn Nix the Fun Way -- a talk on why you may want to use Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # Typst resolves `@preview/<name>:<version>` by downloading from
      # packages.typst.org at compile time, which a sandboxed build cannot do.
      # So pin the whole closure here.
      #
      # Touying pulls in three of these transitively -- and you only find that
      # out inside the sandbox, because an unsandboxed `typst compile` silently
      # populates its own cache over the network and looks like it worked.
      #
      # To re-resolve after a version bump:
      #   tar xzf <pkg>.tar.gz && grep -rhoE '@preview/[a-z0-9_-]+:[0-9.]+' .
      # Names like `your-package` and `hy-dro-gen` are README placeholders,
      # not real dependencies.
      typstDeps = [
        { name = "touying"; version = "0.8.0"; hash = "sha256-f+nu7sxWFPIe5k/+lcFB02qxrgtOyWHm6r8Tq4de9cE="; }
        { name = "uniwarn"; version = "0.1.1"; hash = "sha256-aCR0MtqxsWXBYFVBHA8OwVSmPX/PXvD2WQYmlpXTaOo="; }
        { name = "meander"; version = "0.4.4"; hash = "sha256-F+/47gC4BSEC+phYrvYgP3D2k6woxbU7KxYxD8vesa8="; }
        { name = "mitex"; version = "0.2.6"; hash = "sha256-5FuDQfd04RA2qQkrkhepW3ZW0RrOqcTSTcAo5NyEmDg="; }
      ];

      # reveal.js ships dist/ and plugin/ built in the repo, so no Node build
      # step is needed -- just the tree.
      revealVersion = "5.2.1";
      revealHash = "sha256-f5g09Xj4XF+v6Y6zW13R4PUTWkAt3wwGpa9nSypUV6w=";

      # Provenance for the slide footer (theme.typ): where the source lives,
      # which commit, and the flake's source store path. A derivation cannot
      # name its own output path, but the source path is content-addressed
      # and `nix build <it>#site` rebuilds the deck bit-for-bit -- so that is
      # the store path worth printing. The context is discarded so the footer
      # text does not make the deck depend on every file in the repo.
      repo = "github.com/fzakaria/learn-nix-the-fun-way";
      rev = self.shortRev or self.dirtyShortRev or "dirty";
      srcPath = builtins.unsafeDiscardStringContext self.outPath;
      typstMeta = "--input repo=${repo} --input rev=${rev} --input src=${srcPath}";

      mkDeckPkgs = pkgs: rec {
        inherit (pkgs) lib;

        # Only the files each derivation actually reads. `src = ./.` would
        # sweep in ./result from a dev build, so the derivation hash would
        # change every time you ran `just build` -- which defeats caching and
        # makes `nix build --rebuild` impossible.
        deckSrc = lib.fileset.toSource {
          root = ./.;
          fileset = lib.fileset.unions [ ./deck.typ ./theme.typ ./diagrams.typ ./palette.toml ./images ];
        };
        revealBuildSrc = lib.fileset.toSource {
          root = ./.;
          fileset = lib.fileset.unions [ ./deck.typ ./theme.typ ./diagrams.typ ./palette.toml ./images ./mkreveal.py ];
        };

        # Fonts are pinned deliberately: the code blocks are sized to fit
        # their longest line, so a different mono font means different sizes.
        # Noto Color Emoji is for the 👋 💖 🚀 on the slides; typst's
        # --font-path takes a ':'-separated list.
        fontPath = "${pkgs.dejavu_fonts}/share/fonts/truetype:${pkgs.noto-fonts-color-emoji}/share/fonts";

        # The offline package root handed to typst as TYPST_PACKAGE_CACHE_PATH.
        typstPackages = pkgs.runCommand "typst-packages" { } (
          ''mkdir -p $out/preview'' + "\n" + builtins.concatStringsSep "\n" (
            map
              (p:
                let
                  src = pkgs.fetchurl {
                    url = "https://packages.typst.org/preview/${p.name}-${p.version}.tar.gz";
                    inherit (p) hash;
                  };
                in
                ''
                  mkdir -p $out/preview/${p.name}/${p.version}
                  tar xzf ${src} -C $out/preview/${p.name}/${p.version}
                '')
              typstDeps
          )
        );

        revealSrc = pkgs.fetchFromGitHub {
          owner = "hakimel";
          repo = "reveal.js";
          rev = revealVersion;
          hash = revealHash;
        };

        deck = pkgs.stdenvNoCC.mkDerivation {
          pname = "learn-nix-the-fun-way-deck";
          version = "1.0";
          src = deckSrc;
          nativeBuildInputs = [ pkgs.typst ];
          buildPhase = ''
            runHook preBuild
            export TYPST_PACKAGE_CACHE_PATH=${typstPackages}
            export XDG_CACHE_HOME=$TMPDIR
            # Typst stamps a creation date into the PDF; pin it or every
            # build differs by a few bytes and `nix build --rebuild` fails.
            export SOURCE_DATE_EPOCH=0

            tc() { typst compile --root . --font-path ${fontPath} ${typstMeta} "$@"; }

            # One source, three outputs. `notes` is ours; see theme.typ.
            tc deck.typ deck.pdf                                    # project this
            tc --input notes=right deck.typ deck-presenter.pdf      # slide | notes
            tc --input notes=only  deck.typ deck-notes.pdf          # notes alone

            # Sidecar metadata for pdfpc / pympress. Not layout.
            typst eval --root . --font-path ${fontPath} \
              'query(<pdfpc-file>).first().value' --in deck.typ > deck.pdfpc
            runHook postBuild
          '';
          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp deck.pdf deck-presenter.pdf deck-notes.pdf deck.pdfpc $out/
            runHook postInstall
          '';
        };

        # The same deck as a reveal.js site: Typst exports one SVG per page,
        # the pdfpc sidecar supplies the notes, and mkreveal.py stitches them
        # together. Gets you reveal's speaker view (press S) in a browser.
        reveal = pkgs.stdenvNoCC.mkDerivation {
          pname = "learn-nix-the-fun-way-reveal";
          version = "1.0";
          src = revealBuildSrc;
          nativeBuildInputs = [ pkgs.typst pkgs.python3 ];
          buildPhase = ''
            runHook preBuild
            export TYPST_PACKAGE_CACHE_PATH=${typstPackages}
            export XDG_CACHE_HOME=$TMPDIR
            export SOURCE_DATE_EPOCH=0

            mkdir -p svg
            # `anim=1` marks GIFs for mkreveal.py to animate; see theme.typ.
            typst compile --format svg --root . --font-path ${fontPath} \
              ${typstMeta} --input anim=1 deck.typ 'svg/slide-{0p}.svg'

            python3 mkreveal.py \
              --svg-dir svg \
              --pdfpc ${deck}/deck.pdfpc \
              --reveal ${revealSrc} \
              --out $out
            runHook postBuild
          '';
          installPhase = "true"; # mkreveal.py writes straight to $out
          dontFixup = true;
        };

        # Everything served, as one tree: the PDFs, the reveal.js build under
        # reveal/, and a landing page linking them. `nix run` serves this and
        # the GitHub Pages workflow publishes it, so the two cannot differ.
        # All links are relative, so it works under a Pages project subpath.
        site = pkgs.runCommand "learn-nix-the-fun-way-site" { } ''
          mkdir -p $out
          install -m644 ${deck}/* $out/
          cp -r --no-preserve=mode ${reveal} $out/reveal
          cat > $out/index.html <<'HTML'
          <!doctype html><meta charset="utf-8">
          <title>Learn Nix the Fun Way</title>
          <style>
            body { margin:0; font:16px/1.5 system-ui,sans-serif;
                   background:#fcfcfb; color:#0b0b0b }
            main { max-width:44rem; margin:4rem auto; padding:0 1.5rem }
            h1 { font-size:1.6rem; margin:0 0 .3rem }
            p.sub { color:#898781; margin:0 0 2rem }
            a.card { display:block; padding:1rem 1.2rem; margin:.6rem 0;
                     border:1px solid #e1e0d9; border-radius:8px;
                     text-decoration:none; color:inherit; background:#fff }
            a.card:hover { border-color:#2a78d6 }
            b { display:block; color:#2a78d6 }
            span { color:#52514e; font-size:.92rem }
          </style>
          <main>
            <h1>Learn Nix the Fun Way</h1>
            <p class="sub">Why I love Nix, and you should too &middot; Farid Zakaria</p>
            <a class="card" href="reveal/"><b>Present in the browser</b>
               <span>reveal.js. Press <b style="display:inline">S</b> for the speaker view:
               notes, next slide and a timer on a second screen.</span></a>
            <a class="card" href="deck.pdf"><b>Slides (PDF)</b>
               <span>What you project, if the browser is not an option.</span></a>
            <a class="card" href="deck-presenter.pdf"><b>Presenter view</b>
               <span>Each page is the slide beside its speaker notes.</span></a>
            <a class="card" href="deck-notes.pdf"><b>Notes only</b>
               <span>The narration, without the slides.</span></a>
            <a class="card" href="deck.pdfpc"><b>deck.pdfpc</b>
               <span>Notes as metadata, for pdfpc or pympress.</span></a>
            <p class="sub" style="margin-top:2rem">
               Source: <a href="https://${repo}">${repo}</a> @
               <a href="https://${repo}/commit/${rev}"><code>${rev}</code></a><br>
               Rebuild: <code>nix build ${srcPath}#site</code><br>
               Based on the blog post
               <a href="https://fzakaria.com/2024/07/05/learn-nix-the-fun-way.html">Learn Nix the Fun Way</a>.</p>
          </main>
          HTML
        '';
      };
    in
    {
      packages = forAll (pkgs:
        let d = mkDeckPkgs pkgs; in
        {
          inherit (d) deck reveal site typstPackages;
          default = d.deck;
        });

      devShells = forAll (pkgs:
        let d = mkDeckPkgs pkgs; in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.typst
              pkgs.tinymist # language server, for editor support
              pkgs.typstyle # formatter
              pkgs.just
              pkgs.python3 # mkreveal.py
              pkgs.pdfpc # presenter console; reads deck.pdfpc
            ];

            # The same pins `nix build` uses, so the fast loop cannot drift
            # from the hermetic one.
            TYPST_PACKAGE_CACHE_PATH = "${d.typstPackages}";
            DECK_FONT_PATH = d.fontPath;
            REVEAL_SRC = "${d.revealSrc}";

            shellHook = ''
              echo "learn-nix-the-fun-way  ·  typst $(typst --version | cut -d' ' -f2)"
              echo "  just watch     live-reload deck.pdf (millisecond rebuilds)"
              echo "  just present   pdfpc with speaker notes on a second screen"
              echo "  just reveal    reveal.js site in ./site (S = speaker view)"
              echo "  nix build      hermetic PDFs -> ./result/"
            '';
          };
        });

      # `nix run` builds every variant and serves them, so you can read the
      # deck -- and the presenter view -- in a browser on your laptop.
      #
      #   nix run                http://<host>:8000/
      #   nix run . -- 8080      another port
      #   nix run . -- 8080 ::1  loopback only
      #
      # Binds `::` by default -- dual-stack, so IPv4 still works via
      # v4-mapped addresses -- which makes it reachable from a laptop when
      # the deck is built on a remote machine.
      apps = forAll (pkgs:
        let
          d = mkDeckPkgs pkgs;
          serve = pkgs.writeShellApplication {
            name = "serve-deck";
            runtimeInputs = [ pkgs.python3 ];
            text = ''
              port="''${1:-8000}"
              bind="''${2:-::}"

              # The store is read-only and http.server wants a directory, so
              # stage a copy. Removed on exit.
              root=$(mktemp -d)
              trap 'rm -rf "$root"' EXIT
              cp -r --no-preserve=mode ${d.site}/. "$root/"

              fqdn=$(hostname -f 2>/dev/null || hostname)
              echo
              echo "  remote : http://''${fqdn}:''${port}/"
              echo "  local  : http://localhost:''${port}/"
              echo "  present: http://localhost:''${port}/reveal/   (press S for notes)"
              echo
              exec python3 -m http.server "$port" --bind "$bind" --directory "$root"
            '';
          };
          # Not `rec { serve = ...; default = serve; }` -- that binds `serve`
          # to the app attrset and the interpolation above stops resolving to
          # the derivation.
          app = { type = "app"; program = "${serve}/bin/serve-deck"; };
        in
        {
          default = app;
          serve = app;
        });

      formatter = forAll (pkgs: pkgs.nixpkgs-fmt);
    };
}

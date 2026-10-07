// Learn Nix the Fun Way
// Farid Zakaria
//
//   nix build      hermetic PDFs -> ./result/
//   nix run        serve them (and the reveal.js version) over HTTP
//   nix develop    then `just watch`
//
// One headline + one visual or terminal per slide. Narration lives in
// #speaker-note, written as a plain string so `$out`, `${pkgs.curl}` and
// store paths survive untouched. "** click **" in a note marks where the next
// subslide appears.
//
// Code is set NATIVELY (theme.typ's #code / #stepcode / #codeblock) rather
// than pasted as screenshots: it stays sharp at any zoom and the store paths
// can be copied straight off the PDF.
//
// Arc: why this talk is different -> one tiny script, permuted into a dev
// shell, a deployment, a container and a VM -> so what *is* Nix -> what is
// actually going on underneath, for the people who want the mechanism.

#import "@preview/touying:0.8.0": *
#import themes.simple: *
#import "theme.typ": (
  code, codeblock, codecols, deck-theme, green, hash, ink2, mark, muted, orange,
  bare, provenance-block, remember, section, source, speaker-note, statement, stepcode, visual,
)
#import "diagrams.typ": elf-layout, neofetch, store-tree, trinity

#show: deck-theme

// The pinned nixpkgs every example in the talk builds against (NixOS 24.11).
// Keep this commit if you change the listings, or every hash on the slides
// stops matching what the audience gets.

#title-slide(config: config-page(
  background: image("images/nix-wallpaper-nineish-catppuccin-latte-alt.svg",
    width: 100%, height: 100%, fit: "cover"),
))[
  #text(size: 2.2em, weight: "bold")[Learn Nix the Fun Way]

  #v(0.2em)
  #text(size: 1.0em, fill: ink2)[Why I love Nix, and you should too]

  #v(0.8em)
  #text(size: 0.85em)[Farid Zakaria #sym.dot.c #link("mailto:farid.m.zakaria@gmail.com")[farid.m.zakaria\@gmail.com]]

  #v(0.2em)
  #text(size: 0.75em)[#link("https://fzakaria.github.io/learn-nix-the-fun-way")[fzakaria.github.io/learn-nix-the-fun-way]]

  #v(1.2em)
  #provenance-block

  #speaker-note("Hello!

Welcome to my talk on learning Nix the fun way.

This slide deck can be found online at the following link. I welcome improvements,
edits and corrections.")
]

== Hello 👋

#grid(
  columns: (1.6fr, 1fr),
  column-gutter: 1.2em,
  align: horizon,
  text(size: 0.66em)[
    My name is Farid Zakaria, and I'm a software engineer at
    #link("https://www.meta.com/")[Meta], with a PhD from UC Santa Cruz.

    - Long-time Nix user (circa 2018)
    - Introduced Nix at many companies, including Confluent & Google, and an active member
      of their internal communities
    - Written a lot of Nix software and projects, such as
      #link("https://nixmultiverse.com/")[nixmultiverse.com],
      #link("https://omnibin.dev/")[omnibin.dev],
      #link("https://trynix.dev/")[trynix.dev] and
      #link("https://omniflake.com/")[omniflake.com], to name a few
    - Daily drive NixOS on my wonderful #link("https://frame.work")[frame.work] laptop
  ],
  align(center)[
    #box(clip: true, radius: 50%, image("images/headshot.jpg", width: 7cm, height: 7cm, fit: "cover"))

    #v(0.3em)
    #text(size: 0.6em)[
      #link("mailto:farid.m.zakaria@gmail.com")[farid.m.zakaria\@gmail.com] \
      #link("https://www.linkedin.com/in/fmzakari/")[linkedin.com/in/fmzakari] \
      #link("https://x.com/fmzakari")[x.com/fmzakari]
    ]
  ],
)

#speaker-note("Great, so before we begin, let me introduce myself.

My name is Farid Zakaria, and I'm a software engineer at Meta.

I've been using Nix in various capacities for quite a while now. I've presented at a few
previous incarnations of Nix conventions, and I've had the pleasure of bringing Nix into
many of the companies I've worked at, including Confluent and Google.

I'm very bullish on Nix and it has been a source of mostly joy, and it was additionally the
inspiration for a lot of my PhD research.")

== Disclaimer

#visual("images/learning_curve.jpg")

#speaker-note("I have given Nix talks a few times, individually and to groups -- including
to engineering groups. I've noticed that explaining the rationale for Nix, and even Nix
itself, is challenging. It's an active area of discussion within the community.

Even reflecting on my own journey of learning and loving Nix, it took a few iterations, so
I'm pretty empathetic to those that feel they might not understand what the big deal is or
find it too complex.

So the disclaimer is that some of what I demonstrate may be complicated or tough to
understand. What I do hope to convey however is that there is a reason for this
complexity. Software is complex, and aiming for the levels of guarantees that Nix provides
puts you face to face with that complexity.

Please feel free to ask me questions during the talk. I have kept the slides light on
written text, but there are snapshots of code. I have all of the code handy, and if it's
helpful I'm willing to DO IT LIVE and go beyond what is shown.")

#statement[Why I love Nix, and you should too! 💖][
  #speaker-note("Okay, so this is the alternate working title for this talk.

I want to share why I love Nix. Nix has brought a lot of joy and simplification to my
software life, and oftentimes learning it can feel challenging without much insight into
what is the purpose.")
]

#bare[
  #image("images/lecture_ideal.jpg", height: 92%)
  #pause
  #place(bottom + right, dx: -6%, dy: -24%, image("images/phd_thesis.png", width: 24%))

  #speaker-note("I've given a lot of talks about Nix. I've given talks to meetup groups,
friends and plenty internally at the companies I've worked at.

This is how I've always pictured myself giving a talk about Nix.

It's always a noble pursuit where I impart the beautiful knowledge of that which is Nix.

** click **

I tend to always begin these talks at the beginning, by discussing Eelco's PhD, The Purely
Functional Software Deployment Model, where he first shared Nix with the world in 2006.")
]

#bare[
  #image("images/nix_presentation_boring_edited.png", height: 92%)
  #pause
  #place(bottom + right, dx: -6%, dy: -24%, image("images/picard_nix_hash_meme.jpg", width: 24%))

  #speaker-note("In retrospect, this slide better depicts how the talks have gone. People in
attendance are at best totally bored by the nuance and complexity of what I'm discussing.

** click **

At worst, I've immediately turned off potential new Nix-enthusiasts by jumping straight
into academic and dense vocabulary about the ideas and technology that powers Nix.")
]

#statement[
  Let's do it different this time.

  #pause
  #v(0.4em)
  #mark[_Let's learn Nix the fun way._]
][
  #speaker-note("The motivation of this talk is to do it different this time.

** click **

I want to impart the benefits of using Nix by what I believe to be learning Nix the fun
way.")
]

== What is my IP?

#codeblock[
  ```console
  #! /usr/bin/env bash
  > curl -s http://httpbin.org/get | \
      jq --raw-output .origin
  ```
][
  ```
  73.231.52.39
  ```
]

#speaker-note("Let's begin with something seemingly innocuous. Here is a small script to
determine the IP of your current machine.

This should look pretty standard, I'm hoping, to most people, and probably reminiscent of
a lot of scripts we might have written ourselves that stitch a few programs together.

** click **

And it does what it says.")

== The same script, in Nix

#stepcode(leading: 0.22em, height: 98%, steps: ((), range(17, 24)), ```nix
{
  system ? builtins.currentSystem,
  pkgs ?
    let
      # NixOS 24.11
      rev = "5ef6c425980847c78a80d759abc476e941a9bf42";
      url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    in
      import (fetchTarball url) {inherit system;},
}:
derivation {
  name = "what-is-my-ip";
  builder = "/bin/sh";
  args = [
    "-c"
    ''
      ${pkgs.coreutils}/bin/mkdir -p $out/bin
      echo '#!/bin/sh' > $out/bin/what-is-my-ip
      echo '${pkgs.curl}/bin/curl -s http://httpbin.org/get | \
      ${pkgs.jq}/bin/jq --raw-output .origin' \
            >> $out/bin/what-is-my-ip
      ${pkgs.coreutils}/bin/chmod +x $out/bin/what-is-my-ip
    ''
  ];
  system = builtins.currentSystem;
  outputs = ["out"];
}
```)

#speaker-note("Here is what rewriting that same script in the most raw form of Nix might
look like.

I know I just showed you a new language, but for a tiny second just suspend questions you
may have. The only take-away from the language would be that it looks semi-similar to
other languages you may have used; it has a somewhat JSON-like feel to it.

** click **

Here is the important part of this Nix recipe, and it looks similar-ish to what we had
before.")

== The same script, in idiomatic Nix

#stepcode(steps: ((), (5,), ()), ```nix
{
  system ? builtins.currentSystem,
  pkgs ?
    let
      rev = "5ef6c425980847c78a80d759abc476e941a9bf42";
      url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    in
      import (fetchTarball url) {inherit system;},
}:
pkgs.writeShellScriptBin "what-is-my-ip" ''
  ${pkgs.curl}/bin/curl -s http://httpbin.org/get | \
    ${pkgs.jq}/bin/jq --raw-output .origin
''
```)

#speaker-note("But of course, this is not what you'd actually write in Nix. The following is
a little more idiomatic and a lot more terse.

Here it much more resembles the original script.

** click **

For those that might want to follow along now or later, it's important to keep note of
this commit value, and that I'm building this on an amd64 Linux machine.")

== Let's build it

#codeblock[
  ```console
  > nix build -f what-is-my-ip.nix --print-out-paths
  ```
][
  ```
  /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip
  ```
][
  #v(0.6em)
  ```console
  > /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip
  ```
][
  ```
  73.231.52.39
  ```
]

#speaker-note("Let's build it!

** click **

We get some output path, okay cool.

** click **

That output path has the script we created.

** click **

We can execute that script and it works as expected.")

== What did we build?

#codeblock[
  ```console
  > cat /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip
  ```
][
  ```
  #!/nix/store/gwgqdl0242ymlikq9s9s62gkp5cvyal3-bash-5.2p37/bin/bash
  /nix/store/7p8814g62bybwa8blmaqr9piv3vjwan5-curl-8.11.1-bin/bin/curl -s http://httpbin.org/get | \
  /nix/store/jhw7aklgrc23125ysg1mc72y8zq0lndw-jq-1.7.1-bin/bin/jq --raw-output .origin
  ```
]

#speaker-note("What is the script we produced though? Why did we need Nix?

** click **

The output of our script looks very similar now to the original variant we had before,
except everything seems to be prefixed with some long string.")

#statement(size: 0.85em)[
  What is `/nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip`?

  #pause
  #v(0.6em)
  Why do we care about #mark(raw(hash))?

  #pause
  #v(0.6em)
  #code(```console
  > nix derivation show /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip
  ```, grow: false, height: 30%)
][
  #speaker-note("Although I promised not to go too academic into Nix, this part is
important.

** click **

What is that long prefix string ahead of our built script, and similarly found within the
script before each of the tools?

** click **

There's a handy Nix command to show us the meaning of that prefix.")
]

== Hashed into #raw(hash)

#stepcode(leading: 0.18em, height: 98%, steps: ((), (9,), (15,), range(17, 26), (32,), ()), ```json
{
  "/nix/store/rw89fpljini3yx09v83ds4hyl4945lmk-what-is-my-ip.drv": {
    "args": [
      "-e",
      "/nix/store/v6x3cs394jgqfbi0a42pam708flxaphh-default-builder.sh"
    ],
    "builder": "/nix/store/gwgqdl0242ymlikq9s9s62gkp5cvyal3-bash-5.2p37/bin/bash",
    "env": {
      "buildCommand": "<build command>",
      "builder": "/nix/store/gwgqdl0242ymlikq9s9s62gkp5cvyal3-bash-5.2p37/bin/bash",
      "name": "what-is-my-ip",
      "out": "/nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip",
      "stdenv": "/nix/store/cf464y41p2x3lh1qvbg6678lc3f8zbd6-stdenv-linux",
      "system": "x86_64-linux",
      "text": "<contents of script removed for brevity>"
    },
    "inputDrvs": {
      "/nix/store/7k0msqyp2dm021sdj0qjgpkzff8xhqzr-bash-5.2p37.drv": {},
      "/nix/store/a9dyisrdm25k6cprjvyppxrxs3n8b283-jq-1.7.1.drv": {},
      "/nix/store/crgvallixc0kpg62whvkiv6x38p15nqr-curl-8.11.1.drv": {},
      "/nix/store/ycj0m56p8b0rv9v78mggfa6xhm31rww3-stdenv-linux.drv": {}
    },
    "inputSrcs": [
      "/nix/store/v6x3cs394jgqfbi0a42pam708flxaphh-default-builder.sh"
    ],
    "name": "what-is-my-ip",
    "outputs": {
      "out": {
        "path": "/nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip"
      }
    },
    "system": "x86_64-linux"
  }
}
```)

#speaker-note("The whole purpose of Nix is to kind of build this file. This is the recipe
describing what it takes to build our IP script.

** click **

It has a build command.

** click **

The text of our script, which may also be the source code if it's a little more involved.

** click **

The tools we depend on to make the script function, like cURL and jq.

** click **

The system we're running on, since Nix also supports different architectures and operating
systems.

** click **

All of this information is hashed to calculate this prefix.

There's a really mind-bending property though.")

== Extremely strong guarantees

#text(size: 0.85em)[
  Seeing #raw(hash) means we have _extremely_ strong guarantees of the software graph down
  to the commit and build instructions.
]

#visual("images/denaziamigo-doggo.gif", h: 60%)

#speaker-note("That recipe earlier contained the tools we needed, and the source code; each
one also had a unique hash prefix.

There's a level of recursion here that means repeatedly seeing this hash is an incredibly
strong property of reproducibility.

It means not only was our script text the same and tool dependencies the same, but the
same applies to each tool itself and so forth.")

== Once you know your full software graph, everything is a permutation on that

#visual("images/what_is_my_ip_graph.svg", h: 62%)

#align(center, text(size: 0.55em)[
  ```console
  > nix-store --query --graph /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip
  ```
])

#speaker-note("In Nix, you spend considerable time wiring things up, and the purpose is to
completely model your software as a graph.

Turns out that once you have a graph, everything you might want to do in software is a
permutation or transformation on the graph.

Here we have the full dependency graph of our seemingly innocuous script. It's a little
more involved than originally thought.")

== Permutation \#1: a developer shell

#stepcode(steps: ((), (5, 8), ()), ```nix
let
  rev = "5ef6c425980847c78a80d759abc476e941a9bf42";
  url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  pkgs = import (fetchTarball url) {};
  what-is-my-ip = import ./what-is-my-ip.nix {inherit pkgs;};
in
  pkgs.mkShell {
    packages = [what-is-my-ip];

    shellHook = ''
      echo "Hello, Nix!"
    '';
  }
```)

#speaker-note("Okay, here is another Nix snippet. Again ignore the actual syntax, but know
that what we are defining here is a shell environment.

** click **

We import our same script and add it to the packages that we want present in our shell.")

== Permutation \#1: a developer shell

#codeblock[
  ```console
  > nix-shell what-is-my-ip-shell.nix
  ```
][
  ```
  Hello, Nix!
  ```
][
  #v(0.5em)
  ```console
  [nix-shell]
  > which what-is-my-ip
  ```
][
  ```
  /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip
  ```
][
  #v(0.5em)
  ```console
  [nix-shell]
  > /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip
  73.231.52.39
  ```
]

#remember

#speaker-note("Let's enter the shell.

** click **

We see the shell hook we wrote. That's just an aid to demonstrate we entered the shell.

** click ** ** click **

My PATH now contains what-is-my-ip, and importantly at the exact same hash prefix string
we've built before.

** click **

The script also works and runs as we expect.")

== Reproducible developer environments ✔️

#visual("images/boom-mind-blown.gif", h: 80%)

#speaker-note("Wow. Do we all realize what we just did?

We just created a simple way to bring reproducible developer environments to projects.

No need for containers. No need for namespaces. Easy to enter and easy to validate thanks
to that prefix hash.")

#statement(size: 1.05em)[
  We actually know everything about our code now.

  #pause
  #v(0.4em)
  We can now do binary or source deployments 🚀🛠️📦 since we know the full dependency
  closure of our tool(s).

  #pause
  #v(0.4em)
  We #underline[simply copy] the necessary `/nix/store` paths to another machine
  #pause
  #strike[with Nix installed.]

  #pause
  #v(0.4em)
  Profit 🤑
][
  #speaker-note("We actually know everything about our code now.

** click **

Because we know the full dependency closure, we can do binary or source deployments.

** click **

We simply copy the necessary store paths to another machine...

** click **

...and that machine doesn't even need Nix installed.

** click **

Profit.")
]

== Permutation \#2: a deployment

#codeblock[
  ```console
  > nix copy --to ssh://dennard.soe.ucsc.edu \
    $(nix build -f what-is-my-ip.nix --print-out-paths)
  ```
][
  #v(0.5em)
  ```console
  > ssh dennard.soe.ucsc.edu
  Last login: Mon Mar  3 05:02:57 2025 from 73.231.52.39
  ```
][
  #v(0.5em)
  ```console
  [dennard]
  > /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip
  128.114.53.24
  ```
]

#remember

#speaker-note("Here is one such command to copy the graph we saw earlier to another machine.
In this example we are leveraging a nix copy command, but you could do something as dumb
as scp or rsync.

** click **

The items are copied over. Now let's login to the machine.

** click **

The exact store path we want is present there and runs. The fact that it runs means all of
its dependencies, who also have hash prefix strings, are also present.")

== Binary (or source) deployments ✔️

#visual("images/chris-pratt-mind-blown.gif", h: 80%)

#speaker-note("Wow. We just did a deployment of not only our \"code\", which was our script,
but all of its necessary dependencies.

This blows my mind. I can't tell you the number of times in practice I had to coordinate
the runtime needed on the host or some other base library being present.")

== That's awesome! Unfortunately, our company uses Docker / Kubernetes 😔

#let docker-nix = ```nix
let
  rev = "5ef6c425980847c78a80d759abc476e941a9bf42";
  url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  pkgs = import (fetchTarball url) {};
  what-is-my-ip = import ./what-is-my-ip.nix {inherit pkgs;};
in
  pkgs.dockerTools.buildImage {
    name = "what-is-my-ip-docker";
    config = {
      Cmd = ["${what-is-my-ip}/bin/what-is-my-ip"];
    };
  }
```

#uncover("2-", text(size: 0.85em)[
  No problem! Again, once we know the graph of our software everything is
  #underline[just a permutation].
])

#only(1, hide(code(docker-nix, leading: 0.3em, height: 96%)))
#only(2, code(docker-nix, leading: 0.3em, height: 96%))
#only("3-", code(docker-nix, leading: 0.3em, height: 96%, hl: (5, 10)))

#speaker-note("Well, maybe that's a bit aggressive for deployments, and you have already
drunk the kool-aid of Kubernetes.

** click **

No problem! Since we know the graph, everything we'd want is merely a permutation on our
graph.

Here is another snippet, and again ignore the syntax, but know this is creating an OCI
compliant image.

** click **

We set the command of the image to be our what-is-my-ip package.")

== Permutation \#3: a container

#codeblock[
  ```console
  > nix build -f what-is-my-ip-docker.nix --print-out-paths
  ```
][
  ```
  /nix/store/vwlbi7m9123cm6kjy1skh4fskh02c5zc-docker-image-what-is-my-ip-docker.tar.gz
  ```
][
  #v(0.4em)
  ```console
  > docker load /nix/store/vwlbi7m9123cm6kjy1skh4fskh02c5zc-docker-image-what-is-my-ip-docker.tar.gz
  Loaded image: what-is-my-ip-docker:vwlbi7m9123cm6kjy1skh4fskh02c5zc
  ```
][
  #v(0.4em)
  ```console
  > docker run -it what-is-my-ip-docker:vwlbi7m9123cm6kjy1skh4fskh02c5zc
  73.231.52.39
  ```
][
  #v(0.4em)
  ```console
  > docker inspect what-is-my-ip-docker:vwlbi7m9123cm6kjy1skh4fskh02c5zc --format "{{.Config.Cmd}}"
  [/nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip]
  ```
]

#remember

#speaker-note("Let's build the image.

** click **

The output is an OCI tarball.

** click **

We can load that tarball into the docker daemon as normal.

** click **

Running the image works as we'd expect as well.

** click **

Inspecting the image, we see yet again that same prefix hash on our package for the
command to execute -- which continues to give us comfort about the version and state of
our software.")

== Cool! 😎

#text(size: 0.9em)[
  Nix + Docker integrate perfectly. The image produced has only the files exactly
  necessary to run the tool provided, #underline[effectively distroless].

  You can do the same thing for any deployment format!

  #grid(
    columns: (1fr, 1fr),
    [
      - OCI images
      - tarballs
      - self-extracting ZIP
    ],
    [
      - rpm
      - deb
      - Flatpak / AppImage
    ],
  )
]

#speaker-note("Nix and Docker integrate perfectly. The image has exactly the files
necessary to run the tool -- effectively distroless.

And the same trick works for any deployment format: tarballs, RPMs, debs, AppImages. They
are all just another permutation of the graph.")

#statement[A Linux distribution is simply a collection of packages.][
  #speaker-note("Which brings us to the big one. A Linux distribution is simply a
collection of packages.")
]

== Permutation \#4: an operating system

#stepcode(leading: 0.25em, height: 98%, steps: ((), (6, 13, 14, 15), (23,), ()), ```nix
let
  rev = "5ef6c425980847c78a80d759abc476e941a9bf42";
  url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  nixpkgs = fetchTarball url;
  pkgs = import nixpkgs {};
  what-is-my-ip = import ./what-is-my-ip.nix {inherit pkgs;};
  nixos = import "${nixpkgs}/nixos" {
    configuration = {
      users.users.alice = {
        isNormalUser = true;
        # enable sudo
        extraGroups = ["wheel"];
        packages = [
          what-is-my-ip
        ];
        initialPassword = "swordfish";
      };

      system.stateVersion = "24.05";
    };
  };
in
  nixos.vm
```)

#speaker-note("Here is a whole NixOS machine described in Nix.

** click **

Our same script, added to the packages for a user named alice.

** click **

And we ask for it as a virtual machine.")

== Permutation \#4: an operating system

#codeblock(leading: 0.3em, gap: 0.5em, height: 98%)[
  ```console
  > nix build -f what-is-my-ip-vm.nix --print-out-paths
  ```
][
  ```
  /nix/store/k6vqp2hn0gh7r5dmc61f5knqgnqn53wz-nixos-vm
  ```
][
  #v(0.3em)
  ```console
  > QEMU_KERNEL_PARAMS=console=ttyS0 \
      /nix/store/k6vqp2hn0gh7r5dmc61f5knqgnqn53wz-nixos-vm/bin/run-nixos-vm -nographic; reset
  ```
][
  ```
  ... long boot sequence ...

  <<< Welcome to NixOS 24.11pre-git (x86_64) - ttyS0 >>>

  nixos login: alice
  Password:
  ```
][
  #v(0.3em)
  ```console
  [alice@nixos:~]$ which what-is-my-ip
  /etc/profiles/per-user/alice/bin/what-is-my-ip

  [alice@nixos:~]$ realpath $(which what-is-my-ip)
  /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip

  [alice@nixos:~]$ what-is-my-ip
  73.231.52.39
  ```
]

#remember

#speaker-note("Build it.

** click **

A VM.

** click ** ** click **

Boot it, and log in as alice.

** click **

Our script is on alice's PATH, it resolves to the very same store path, and it runs.")

// ---------------------------------------------------------------------------
// So what is Nix? Now that the audience has *seen* it, name the pieces.
// ---------------------------------------------------------------------------

#section[So... what is Nix?][
  #speaker-note("We've now taken one tiny script and turned it into a developer shell, a
deployment, a container and an operating system. So let's step back: what actually is
Nix?")
]

== A language, and a command-line tool

#grid(
  columns: (1fr, 1fr),
  column-gutter: 0.8em,
  align: horizon,
  code(```nix
  # hello-world.nix
  derivation {
    name = "hello-world";
    # POSIX requires this file to be present
    # so we can depend on it but not on /bin/bash
    builder = "/bin/sh";
    args = [ "-c" "echo 'hello world' > $out" ];
    system = builtins.currentSystem;
  }
  ```, grow: false, height: 45%),
  code(```nix
  # hello-world-writeText.nix
  let pkgs = import <nixpkgs> {};
  in
  pkgs.writeText "hello-world" "hello world"
  ```, grow: false, height: 45%),
)

#codeblock[
  ```console
  > nix build --file hello-world.nix --json | jq -r '.[].outputs.out'
  /nix/store/dg2rpsw16yfiw3h2ma14j5qh7a6m08kk-hello-world

  > cat /nix/store/dg2rpsw16yfiw3h2ma14j5qh7a6m08kk-hello-world
  hello world
  ```
]

#speaker-note("Nix is everything, which is part of why it's hard to explain. It began as
Eelco Dolstra's PhD research, and I highly recommend the read.

It's a language, depicted here. It's used ultimately to create what the language refers to
as 'derivations', but you can think of them as build recipes. The language resembles JSON a
little, with the added bonus that it's a pure, functional, lazy, untyped language. It's kind
of like a poor version of Haskell.

It's also the command line tool itself, called nix, with which I can do a bunch of stuff
like build these recipes or create developer environments, as we saw.")

== A package collection: nixpkgs

#grid(
  columns: (2.2fr, 1fr),
  column-gutter: 0.8em,
  align: horizon,
  image("images/repology_graph.png", height: 10.5cm),
  text(size: 0.7em)[
    #link("https://github.com/NixOS/nixpkgs")[github.com/NixOS/nixpkgs]

    #v(0.6em)
    #text(fill: muted)[Repository size vs. freshness, from
      #link("https://repology.org/repositories/graphs")[repology.org]]
  ],
)

#speaker-note("It's a package collection, known as nixpkgs. On repology's map of every
package repository, nixpkgs is out on its own: the largest, and among the freshest.

GitHub publishes a yearly report known as Octoverse, and nixpkgs has been in the top 10
across multiple dimensions such as contributors, activity and pull requests.

Another fun fact: this whole package set can be bootstrapped from a 357-byte binary seed.")

== One recipe, many permutations

#codeblock[
  ```console
  > nix run nixpkgs#hello
  Hello, world!
  ```
][
  ```console
  > nix build nixpkgs#hello --no-link --print-out-paths
  /nix/store/m1r53pnnm6hnjwyjmxska24y8amvlpjp-hello-2.12.1
  ```
][
  ```console
  > nix build nixpkgs#pkgsStatic.hello --no-link --print-out-paths
  /nix/store/d3scd1vhylfvjgjwgp2ydbhdlss7zpcr-hello-static-x86_64-unknown-linux-musl-2.12.1
  ```
][
  ```console
  > nix build nixpkgs#pkgsCross.riscv64.hello --no-link --print-out-paths
  /nix/store/p2fhzrphxmd8if2mf7b28biawj7walf1-hello-riscv64-unknown-linux-gnu-2.12.1
  > /nix/store/p2fhzrphxmd8if2mf7b28biawj7walf1-hello-riscv64-unknown-linux-gnu-2.12.1/bin/hello
  bash: .../bin/hello: cannot execute binary file
  ```
][
  ```console
  > nix build nixpkgs#pkgsCross.mingwW64.hello --no-link --print-out-paths
  /nix/store/b78fyx3z62pdww8a3nk8vfa3cb2api6h-hello-x86_64-w64-mingw32-2.12.1
  > wine64 /nix/store/b78fyx3z62pdww8a3nk8vfa3cb2api6h-hello-x86_64-w64-mingw32-2.12.1/bin/hello.exe
  Hello, world!
  ```
]

#speaker-note("Because nixpkgs is a graph, a package is not one thing, it's a recipe you
can permute.

** click **

Here's GNU hello, built normally.

** click **

The same hello, statically linked against musl. One attribute.

** click **

Cross-compiled for RISC-V. It won't run on my x86 laptop, which is the point.

** click **

Or for Windows, and we can run it under wine. Same recipe, every time; just a different
path through the graph.")

== A store

#align(center + horizon, grid(
  columns: 2, column-gutter: 2.5em,
  store-tree(lh: 10.2pt, size: 7.8pt),
  store-tree(lh: 10.2pt, size: 7.8pt, closure: range(7, 21)),
))

#source[#link("https://edolstra.github.io/pubs/phd-thesis.pdf")[Eelco Dolstra, _The Purely Functional Software Deployment Model_ (2006)], redrawn]

#speaker-note("It's a store. This is actually a very important distinction that separates
Nix from traditional software installations: it forgoes the Filesystem Hierarchy Standard,
the well-known directories like /lib and /etc that we all know and love.

By forgoing that limitation, Nix is capable of having limitless variants of a single
package, since they are no longer confined to a single key space.

Furthermore, dependencies of Nix software only exist within other store entries, forming a
DAG.")

== An operating system

#align(center + horizon, neofetch)

#speaker-note("It's an operating system. Once you have solved producing software packages,
a Linux distribution is merely a collection of software packages and a kernel.")

#bare[
  #let label(body, angle: 0deg) = text(size: 0.65em, fill: ink2, rotate(angle, reflow: true, body))
  #grid(
    columns: (1fr, 1fr, 1fr),
    rows: (1fr, auto, 1fr),
    align: center + horizon,
    label[Nix Language], label[Nix Operating System], label(angle: 12deg)[Nix Package Manager],
    grid.cell(colspan: 3, inset: 0.8em,
      text(size: 1.5em, weight: "bold")[Modeling software as a \ directed acyclic graph.]),
    label(angle: -30deg)[Nix Ecosystem], stack(spacing: 1.2em, label[Nix Build System], label[Nix Stores]),
    stack(spacing: 1.2em, label(angle: 25deg)[Nix Command Line Tools], label[Developer Environments]),
  )

  #speaker-note("Fundamentally though, Nix is the idea of modeling all software as a
directed acyclic graph with an immense level of fidelity.

It's an idea that says: what if every part of our build system was accounted for?

The language, the store, the package set, the OS, the dev shells -- they're all just ways
of building, storing and walking that graph.")
]

== The declarative trinity

#align(center + horizon, trinity(s: 10.5cm))

#source[Understand NixOS, redrawn]

#speaker-note("Which is why the naming is so confusing. Nix the language, Nix the package
manager, and NixOS the operating system are all called Nix, but none of them is the other.
What they share is the graph.")

// ---------------------------------------------------------------------------
// Under the hood: the mechanism, for the people who want it. Uses Ruby as the
// innocent bystander because it is in every distro and "obviously" simple.
// ---------------------------------------------------------------------------

#section(sub: [How does any of this actually work?])[Under the hood][
  #speaker-note("For the last part, let's go one level down and look at the mechanism.

I'm going to go over very briefly how software is laid out traditionally, hopefully
illuminate how it's utter madness, and then tie the thread to see how Nix solves it.

A recurring theme: Docker, specifically containers, are not a solution to any of this.
Containers are just a snapshot at a particular state.")
]

== A story about Ruby

#codeblock[
  ```console
  > ls /usr/bin/ruby*
  /usr/bin/ruby  /usr/bin/ruby3.0  /usr/bin/ruby3.1
  ```
][
  #v(0.5em)
  ```console
  > /usr/bin/ruby3.1 --version
  ruby 3.1.2p20 (2022-04-12 revision 4491bb740a) [x86_64-linux-gnu]
  ```
]

#speaker-note("I'm going to pick Ruby, as it's an innocuous piece of software. It's written
in C, present on every distribution, and would seemingly have a very small set of
dependencies.

Here are the Rubies on a typical machine.

** click **

Which one is this? What was it built with?")

== Building Ruby

#grid(
  columns: (1fr, 1fr), column-gutter: 1.5em,
  text(size: 0.56em)[
    + Install the prerequisite dependencies for building the CRuby interpreter:
      - C compiler

      For RubyGems, you will also need:
      - `OpenSSL` 1.1.x or 3.0.x / LibreSSL
      - libyaml 0.1.7 or later
      - zlib

      If you want to build from the git repository, you will also need:
      - autoconf - 2.67 or later
      - gperf - 3.1 or later
        - Usually unneeded; only if you edit some source files using gperf
      - ruby - 2.5 or later
        - We can upgrade this version to system ruby version of the latest Ubuntu LTS.
  ],
  text(size: 0.56em)[
    #set enum(start: 2)
    + Install optional, recommended dependencies:
      - libffi (to build fiddle)
      - gmp (if you wish to accelerate Bignum operations)
      - libexecinfo (FreeBSD)
      - rustc - 1.58.0 or later, if you wish to build YJIT.

    #v(1em)
    #text(fill: muted)[From Ruby's #link("https://docs.ruby-lang.org/en/master/contributing/building_ruby_md.html")[building_ruby.md]]
  ],
)

#speaker-note("Ruby's own build instructions. A C compiler, OpenSSL, libyaml, zlib -- and if
you build from git, autoconf, gperf, and a Ruby to build Ruby. Plus optional extras.

Where does each of these come from on your machine? What version?")

== What does it actually load?

#codeblock[
  ```console
  > libtree /usr/bin/ruby3.1 -p
  /usr/bin/ruby3.1
  ├── /lib/x86_64-linux-gnu/libruby-3.1.so.3.1
  │   ├── /lib/x86_64-linux-gnu/libz.so.1
  │   ├── /lib/x86_64-linux-gnu/libcrypt.so.1
  │   └── /lib/x86_64-linux-gnu/libgmp.so.10
  ├── /lib/x86_64-linux-gnu/libcrypt.so.1
  ├── /lib/x86_64-linux-gnu/libgmp.so.10
  └── /lib/x86_64-linux-gnu/libz.so.1
  ```
]

#speaker-note("Here is what the installed ruby resolves at runtime. Everything comes from
one shared /lib, by name only. Whatever libz.so.1 happens to be there, wins.")

== ...and everything it loads, loads

#codeblock(leading: 0.2em, height: 98%, grid(
  columns: 2, column-gutter: 2.5em,
  ```console
  > libtree /usr/bin/ruby3.1 -vvv
  /usr/bin/ruby3.1
  ├── libruby-3.1.so.3.1 [ld.so.conf]
  │   ├── libz.so.1 [ld.so.conf]
  │   │   └── libc.so.6 [ld.so.conf]
  │   │       └── ld-linux-x86-64.so.2 [ld.so.conf]
  │   ├── ld-linux-x86-64.so.2 [ld.so.conf]
  │   ├── libc.so.6 [ld.so.conf]
  │   │   └── ld-linux-x86-64.so.2 [ld.so.conf]
  │   ├── libm.so.6 [ld.so.conf]
  │   │   ├── libc.so.6 [ld.so.conf]
  │   │   │   └── ld-linux-x86-64.so.2 [ld.so.conf]
  │   │   └── ld-linux-x86-64.so.2 [ld.so.conf]
  │   ├── libcrypt.so.1 [ld.so.conf]
  │   │   └── libc.so.6 [ld.so.conf]
  │   │       └── ld-linux-x86-64.so.2 [ld.so.conf]
  │   └── libgmp.so.10 [ld.so.conf]
  │       └── libc.so.6 [ld.so.conf]
  │           └── ld-linux-x86-64.so.2 [ld.so.conf]
  ```,
  ```console
  ├── libc.so.6 [ld.so.conf]
  │   └── ld-linux-x86-64.so.2 [ld.so.conf]
  ├── libm.so.6 [ld.so.conf]
  │   ├── libc.so.6 [ld.so.conf]
  │   │   └── ld-linux-x86-64.so.2 [ld.so.conf]
  │   └── ld-linux-x86-64.so.2 [ld.so.conf]
  ├── libcrypt.so.1 [ld.so.conf]
  │   └── libc.so.6 [ld.so.conf]
  │       └── ld-linux-x86-64.so.2 [ld.so.conf]
  ├── libgmp.so.10 [ld.so.conf]
  │   └── libc.so.6 [ld.so.conf]
  │       └── ld-linux-x86-64.so.2 [ld.so.conf]
  └── libz.so.1 [ld.so.conf]
      └── libc.so.6 [ld.so.conf]
          └── ld-linux-x86-64.so.2 [ld.so.conf]
  ```,
))

#speaker-note("And with the full verbose tree, every library pulls in more libraries, all
resolved the same way: by name, from a single global directory.")

== Ruby, as Nix sees it

#visual("images/ruby_graph.png", h: 72%)

#align(center, text(size: 0.55em)[
  ```console
  > nix-store --query --include-outputs --graph \
      $(nix-store --query --deriver $(nix eval nixpkgs#ruby.outPath --raw))
  ```
])

#speaker-note("And this is Ruby's full build graph in nixpkgs, every input accounted for.
This is the thing Nix makes you model -- and once you have it, everything else we saw today
falls out of it.")

== Quick primer: what's a binary?

#grid(
  columns: (auto, 1fr),
  column-gutter: 0.8em,
  align: horizon,
  elf-layout(w: 5.2cm, rh: 1.05cm),
  codeblock(width: 100%)[
    ```console
    $ readelf -a $(which ruby) | grep NEEDED
     0x0000000000000001 (NEEDED)   Shared library: [libruby-2.7.so.2.7]
     0x0000000000000001 (NEEDED)   Shared library: [libc.so.6]
    $ readelf -a libruby-2.7.so.2.7 | grep NEEDED
     0x0000000000000001 (NEEDED)   Shared library: [libpthread.so.0]
     0x0000000000000001 (NEEDED)   Shared library: [librt.so.1]
     0x0000000000000001 (NEEDED)   Shared library: [libgmp.so.10]
     0x0000000000000001 (NEEDED)   Shared library: [libdl.so.2]
     0x0000000000000001 (NEEDED)   Shared library: [libcrypt.so.1]
     0x0000000000000001 (NEEDED)   Shared library: [libm.so.6]
     0x0000000000000001 (NEEDED)   Shared library: [libc.so.6]
     0x0000000000000001 (NEEDED)   Shared library: [ld-linux-x86-64.so.2]
    ```
  ],
)

#source[#link("https://commons.wikimedia.org/wiki/File:Elf-layout--en.svg")[Surueña, CC BY-SA 3.0], redrawn]

#speaker-note("A quick primer on what a binary is in Linux. All binaries on Linux are in
the ELF format. It's an incredibly generic format.

Specifically, a dynamic binary must have an interpreter set, which is always the dynamic
linker, and can list the libraries it needs. Note that NEEDED entries are just names --
not paths, and not versions.")

== An alternative to the FHS model

#grid(
  columns: (auto, 1fr),
  column-gutter: 0.8em,
  align: horizon,
  store-tree(lh: 10.6pt, size: 8pt),
  codeblock(width: 100%)[
    ```console
    $ patchelf --print-rpath ruby | tr ':' '\n'
    /nix/store/yyhykbfxj6jfc62x4f9a2awfbch605fd-ruby-2.6.6/lib
    /nix/store/6hhqb94ilrdmh0cx5bhdqb92m6bqkvdj-zlib-1.2.11/lib
    /nix/store/90illc73xfs933d06daq6d41njs8yh66-glibc-2.32-37/
    ```
  ],
)

#source[#link("https://edolstra.github.io/pubs/phd-thesis.pdf")[Eelco Dolstra, _The Purely Functional Software Deployment Model_ (2006)], redrawn]

#speaker-note("This slide won't do the concept justice at all, so I apologize; I could
probably spend multiple hours talking about it.

In order to add reproducibility to the world of software management, a new concept was
developed in the early 2000s as part of a PhD thesis. The idea was to nest all software
underneath a single root, include a cryptographic hash in the name so similar packages
could live side by side, and restrict all dependencies to other entries in the root, or
store.

Dynamic linking relies on a feature to specify an RPATH on the binary, which supersedes the
FHS search. Each NEEDED name now resolves against exact store paths.

Similar to RPATH, the developer environments set the PATH variable to isolate access to the
current terminal.")

== When you discover NixOS

#visual("images/when_you_discover_nixos.jpg", h: 72%)

#align(center, text(size: 0.5em, fill: muted,
  link("https://www.reddit.com/r/NixOS/comments/p132mz/when_you_discover_nixos/")))

#speaker-note("And that's how it feels once it clicks.")

#bare[
  #text(size: 2.0em, weight: "bold")[Fin.]

  #v(0.6em)
  #text(size: 0.9em)[Thank you!]

  #v(0.6em)
  #text(size: 0.75em)[#link("https://fzakaria.github.io/learn-nix-the-fun-way")[fzakaria.github.io/learn-nix-the-fun-way]]

  #text(size: 0.75em)[#link("https://fzakaria.com/2024/07/05/learn-nix-the-fun-way.html")[fzakaria.com/2024/07/05/learn-nix-the-fun-way.html]]

  #speaker-note("Thank you! The slides and every example are online; questions welcome.")
]

---
# You can also start simply with 'default'
theme: default

background: /nix-wallpaper-nineish-catppuccin-latte-alt.svg
# some information about your slides (markdown enabled)
title: Learn Nix the Fun Way
info: |
  This is a talk I am giving at NixPlanet 2025 (https://planetnix.com/) on why you may want use Nix.
# apply unocss classes to the current slide
class: text-center
# https://sli.dev/features/drawing
drawings:
  persist: false
# slide transition: https://sli.dev/guide/animations.html#slide-transitions
transition: slide-left
# enable MDC Syntax: https://sli.dev/features/mdc
mdc: true
---

# Learn Nix the Fun Way

PlanetNix (SCaLE 22x), Pasadena, CA 2025

Farid Zakaria <farid.m.zakaria@gmail.com>

<a href="https://fzakaria.github.io/learn-nix-the-fun-way">fzakaria.github.io/learn-nix-the-fun-way</a>
<GitCommitComponent />

<style>

.git-commit {
  position: absolute;
  bottom: 0;
  left: 50%;
  transform: translateX(-50%);
  margin: auto;
  margin-bottom: 40px;
}

</style>

<!--
Hello!

Welome to my talk on learning Nix the fun way.

This slide deck can be found online at the following link.
I welcome improvements, edits and corrections.
-->

---
transition: fade-out
layout: two-cols
---

# Hello 👋

My name is Farid Zakaria, and I'm a software engineer at [Confluent](https://www.confluent.io/) mostly working on Bazel and pursuing a nearly-complete PhD at UC Santa Cruz.

- "Long-time" Nix user (circa 2025)
- Introduced Nix at [Looker](https://cloud.google.com/looker) (acquired by Google) and active member of internal community
- Migrated a substantial JRuby, Java, Kotlin & JavaScript codebase to Nix; mostly via `nix-shell`
- Daily drive NixOS on my wonderful [frame.work](https://frame.work) laptop
- Leverage Nix for a lot of my PhD work (come find me to talk about ongoing reasearch)

::right::

<div style="margin-top: -40px">
  <img src="./images/headshot.jpg"/>

  <div style="margin-top:-50px; text-align: center;">

[farid.m.zakaria@gmail.com](mailto:farid.m.zakaria@gmail.com)

[linkedin.com/in/fmzakari/](https://www.linkedin.com/in/fmzakari/)

[x.com/fmzakari](https://x.com/fmzakari)

  </div>
</div>

<style>
h1 {
  background-color: #2B90B6;
  background-image: linear-gradient(45deg,rgb(158, 212, 78) 10%,rgb(140, 118, 20) 20%);
  background-size: 100%;
  -webkit-background-clip: text;
  -moz-background-clip: text;
  -webkit-text-fill-color: transparent;
  -moz-text-fill-color: transparent;
}

img {
  margin-left: 3em;
  width: 300px;
  height: auto;
  clip-path: circle();

}
</style>

<!--
Great, so before we begin, let me introduce myself.

My name is Farid Zakaria, and I'm a Principal Engineer at the moment at Confluent most known for their product Apache Kafka. I'm working on build systems, specifically Bazel.

I've been using Nix in various capacities for quite a while now. I've presented at a few previous incarnations of Nix conventions and even had the pleasure of brining Nix into my previous employer Looker which was acquired by Google.

I'm very bullish on Nix and it has been a source of mostly joy, and it's additionally been the inspiration for a lot of my PhD research.

You rarely get a chance to talk to anyone about the details of research, especially Nix, so come find me if you'd like to learn more.
-->

---
layout: statement
---

Why I love Nix, and you should too! 💖

<style>
p {
  font-size: 2em;
}
</style>

<!--
Okay, so this is the alternate working title for this talk.

I want to share why I love Nix. Nix has brought a lot of joy,
simplification to my software life and oftentimes learning it can
feel challenging without much insight into what is the purpose.
-->

---
layout: center
transition: fade
---

<div>
  <img src="./images/lecture_ideal.jpg" alt="">
  <img v-click src="./images/phd_thesis.png"
  width="300" height="auto"
  style="position: absolute; bottom: 30%; left: 60%; z-index: 1;" />>
</div>

<!--
I've given a lot of talks about Nix. I've given talks to meetup groups,
friends and plenty internally at the companies I've worked at.

This is how I've always pictured myself giving a talk about Nix.

It's always a nobel pursuit where I impart the beautiful knowledge of that which is Nix.

** click **

I tend to always begin these talks by starting at the beginning by discusisng Eelco's PhD, The Purely Functional Software Deployment Model, where he first shared Nix with the world in 2006
-->

---
layout: center
transition: slide-left
---

<div>
  <img src="./images/nix_presentation_boring_edited.png" alt="">

<img v-click src="./images/picard_nix_hash_meme.jpg"
  width="300" height="auto"
  style="position: absolute; bottom: 30%; left: 60%; z-index: 1;" />

</div>

<!--
In retrospect, this slide better depicts how the talks have gone.
People in attendance are at best totally bored by the nuance and complexity of what I'm discussing.

** click ** 

At worst, I've immediately turned off potential new Nix-enthusiasts by immediately jumping into academic and dense vocabulary about the ideas and technology that powers Nix.
-->

---
layout: statement
---

Let’s do it different this time.

<span v-click v-mark.underline.green>_Let’s learn Nix the fun way._</span>

<style>
p {
  font-size: 2em;
  line-height: 2em; 
}
</style>

<!--
The motivation of this talk is to do it different this time.

** click **

I want to impart the benefits of using Nix by what I believe to be
learning Nix the fun way.
-->

---
layout: center
transition: slide-up
---

# What is my IP ?

<div style="--slidev-code-font-size: 30px; --slidev-code-line-height: 50px;">

````md magic-move
```bash {all}
#! /usr/bin/env bash
> curl -s http://httpbin.org/get | \
    jq --raw-output .origin
```

```bash {all}
#! /usr/bin/env bash
> curl -s http://httpbin.org/get | \
    jq --raw-output .origin
73.231.52.39
```
````

</div>

<!--
Let's begin with something seemingly innocuous.
Here is a small script to determine the IP of your current machine.

This should look pretty standard, I'm hoping to most people and probably
reminiscent of a lot of scripts we might have written ourselves that stitches a few programs together.

** click **
-->

---
layout: center
---

````md magic-move
```nix {all|15-21}
{
  system ? builtins.currentSystem,
  pkgs ?
    # NixOS24.11
    import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/5ef6c425980847c78a80d759abc476e941a9bf42.tar.gz") {
      inherit system;
    },
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
```

```nix {all|4|all}
{
  system ? builtins.currentSystem,
  pkgs ?
    import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/5ef6c425980847c78a80d759abc476e941a9bf42.tar.gz") {
      inherit system;
    },
}:
pkgs.writeShellScriptBin "what-is-my-ip" ''
  ${pkgs.curl}/bin/curl -s http://httpbin.org/get | \
    ${pkgs.jq}/bin/jq --raw-output .origin
''
```
````

<!--
Here is what rewriting that same script in the most raw-form of Nix you might do.

I know I just showed you a new language but for a tiny second just suspend questions you may have. The only take-away from the language my goal would be that it looks semi-similar to other languages you may have used; it has a somewhat JSON-like feel to it.

** click **

Here is the important part of this Nix recipe and it looks similar-ish to
what we had before. 

** click **

But of course, this is not what you'd actually write in Nix.
The following is a little more idiomatic and a lot more terse.

Here it much more resembles the original script.

** click **

For those that might want to follow along now or later, it's important to keep note of this commit value and that I'm building this on an amd64 Linux machine.
-->

---
layout: center
---

<div style="--slidev-code-font-size: 20px; --slidev-code-line-height: 1.5em; max-width:100%">

````md magic-move
```shell {all}
> nix build -f what-is-my-ip.nix --print-out-paths
```

```shell {2}
> nix build -f what-is-my-ip.nix --print-out-paths
/nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip
```

```shell
> /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip
```

```shell
> /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip
73.231.52.39
```
````

</div>

<!--
Let's build it!

** click **

We get some output path, okay cool.

** click **

That output path has the script we created.

** click **

We can execute that script and it works as expected.
-->

---
layout: center
---

<div style="--slidev-code-font-size: 0.8em; --slidev-code-line-height: 1.5em;">

````md magic-move
```console
> cat /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip
```

```console
> cat /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip
#!/nix/store/gwgqdl0242ymlikq9s9s62gkp5cvyal3-bash-5.2p37/bin/bash
/nix/store/7p8814g62bybwa8blmaqr9piv3vjwan5-curl-8.11.1-bin/bin/curl -s http://httpbin.org/get | \
/nix/store/jhw7aklgrc23125ysg1mc72y8zq0lndw-jq-1.7.1-bin/bin/jq --raw-output .origin
```
````

</div>

<!--
What is the script we produced though?
Why did we need Nix?

** click **

The output of our script looks very similar now to the original variant
we had before except everything seems to be prefixed with some long string.
-->

---
layout: center
---

What is `/nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip` ?

<v-clicks at="1">

Why do we care about <code v-mark.underline.green>y2g0ijqqiyi9vxr9xgmvvgblxqflqzav</code>?

<v-click>
```console
> nix derivation show /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip
```
</v-click>
</v-clicks>

<!--
Although I promised not to go too academic into Nix; this part is important.

** click **

What is that long prefix string ahead of our built script and similarly found within the script before each of the tools?

** click ** 

There's a handy Nix command to show us the meaning of that prefix.
-->

---
layout: center
---

The following is <i>hashed</i> to calculate <code>y2g0ijqqiyi9vxr9xgmvvgblxqflqzav</code>.

```json {all|9|15|17-25|32|all}{maxHeight:'500px'}
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
```

<!--
The whole purpose of Nix is to kind of build this file.
This is the recipe describing what it takes to build our IP script.

** click **

It has a build commmand

** click **

The text of our script which may also be the source code if it's a little more involved.

** click **

The tools we depend on to make the script function like cURL and jq.

** click **

The system we're running on since Nix also supports different architectures and operating systems.

** click **

All of this information is hashed to calculate this prefix.

There's a really mind-bending property though.
-->

---
layout: default
---

<p>
Seeing <code>y2g0ijqqiyi9vxr9xgmvvgblxqflqzav</code> means we have <i>extremely</i> strong guarantees of the software graph down to the commit and build instructions.
</p>

<img style="margin: auto; height: 400px; width: auto;" src="./images/denaziamigo-doggo.gif"/>

<!--
That recipe earlier contained our necessary tools we needed, and the source code, each one also had a unique hash prefix.

There's a level of recursion here that means repeatedly seeing this hash is an incredibly strong property of reproducibility.

It means not only was our script text the same and tool dependencies the same, but the same applies to each tool itself and so forth.
-->

---
layout: center
---

<p>
Once you know your full software graph, everything is a permutation on that.
</p>

<img src="./images/what_is_my_ip_graph.svg"/>

```console
> nix-store --query --graph /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip
```

<!--
In Nix, you spend considerable time wiring things up in Nix and the purpose to completely model your software as a graph.

Turns out that once you have a graph, everything you might want to do in software is a permutation or transformation on the graph.

Here we have the full dependency graph of our seemingly innocuous script.
It's a little more involved than originally thought.
-->

---
layout: center
---

````md magic-move
```nix {all|3,6|all}
let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/5ef6c425980847c78a80d759abc476e941a9bf42.tar.gz") {};
  what-is-my-ip = import ./what-is-my-ip.nix {inherit pkgs;};
in
  pkgs.mkShell {
    packages = [what-is-my-ip];

    shellHook = ''
      echo "Hello, PlanetNix!"
    '';
  }
```

```console
> nix-shell what-is-my-ip-shell.nix
```

```console
> nix-shell what-is-my-ip-shell.nix
Hello, PlanetNix!
```

```console
> nix-shell what-is-my-ip-shell.nix
Hello, PlanetNix!

[nix-shell]
> which what-is-my-ip
```

```console
> nix-shell what-is-my-ip-shell.nix
Hello, PlanetNix!

[nix-shell]
> which what-is-my-ip
/nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip
```

```console
> nix-shell what-is-my-ip-shell.nix
Hello, PlanetNix!

[nix-shell]
> which what-is-my-ip
/nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip

[nix-shell]
> /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip
73.231.52.39
```
````

Remember <u>y2g0ijqqiyi9vxr9xgmvvgblxqflqzav</u>

<!--
Okay, here is another Nix snippet. Again ignore the actual syntax but know
that what we are defining here is a shell environment.

** click ** 

We import our same script and add it to the packages that we want present in our shell.

** click ** 

Let's enter the shell.

** click **

We see the same shell hook we wrote earlier. That's just an aid to demonstrate we entered the shell.

** click ** 

My PATH now contains what-is-my-ip, and importantly at the exact same
hash prefix string we've built before.

** click ** 

The script also works and runs as we expect.
-->

---
layout: center
---

<h3>Reproducible Developer Environments ✔️</h3>
<p>
  <img src="./images/boom-mind-blown.gif" />
</p>

<!--
Wow.
Do we all realize what we just did ?

We just created a simple way to bring reproducible developer environments for projects.

No need for containers. No need for namespaces. Easy to enter and easy to validate thanks to that prefix hash.
-->

---
layout: center
---

<v-clicks>
We actually know everything about our code know.

We can now do binary or source deployments 🚀🛠️📦 since we know the full dependency closure of our tool(s).
</v-clicks>

<span v-click>We <u>simply copy</u> the necessary <code>/nix/store</code> paths to another machine </span><s v-click>with Nix installed.</s>

<span v-click>Profit 🤑</span>

---
layout: center
---

````md magic-move
```console
> nix copy --to ssh://dennard.soe.ucsc.edu \
  $(nix build -f what-is-my-ip.nix --print-out-paths)
```

```console
> nix copy --to ssh://dennard.soe.ucsc.edu \
  $(nix build -f what-is-my-ip.nix --print-out-paths)

> ssh dennard.soe.ucsc.edu
Last login: Mon Mar  3 05:02:57 2025 from 73.231.52.39
```

```console
> nix copy --to ssh://dennard.soe.ucsc.edu \
  $(nix build -f what-is-my-ip.nix --print-out-paths)

> ssh dennard.soe.ucsc.edu
Last login: Mon Mar  3 05:02:57 2025 from 73.231.52.39

[dennard]
> /nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip
128.114.53.24
```
````

Remember <u>y2g0ijqqiyi9vxr9xgmvvgblxqflqzav</u>

<!--
Here is one such command to copy the graph we saw earlier to another machine. In this example we are leveraging a nix copy command but you could do something as dumb as scp or rsync.

** click **

The items are copied over. Now let's login to the machine.

** click **

The exact store path we want is present there and runs. The fact it runs means that all it's dependencies whom are also have hash prefix strings 
are also present.
-->

---
layout: center
---

<h3>Binary (or source) Deployments ✔️</h3>
<p>
  <img src="./images/chris-pratt-mind-blown.gif" />
</p>

<!--
Wow. We just did a deployment of not only our "code" which was our script
but all of it's necessary dependencies.

This blows my mind. I can't tell you the number of times in practice I had to coordinate the runtime needed on the host or some other base library being present.
-->

---
layout: center
---

That's awesome! Unfortunately, our company uses Docker / Kubernetes 😔.

<v-clicks>

No problem! Again, once we know the graph of our software everything is <u>just a permutation</u>.

```nix {all|3,8|all}
let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/5ef6c425980847c78a80d759abc476e941a9bf42.tar.gz") {};
  what-is-my-ip = import ./what-is-my-ip.nix {inherit pkgs;};
in
  pkgs.dockerTools.buildImage {
    name = "what-is-my-ip-docker";
    config = {
      Cmd = ["${what-is-my-ip}/bin/what-is-my-ip"];
    };
  }
```

</v-clicks>

<!--
Well maybe that's a bit aggressive for deployments and you have already drank the kool-aid of kubernetes.

** click ** 

No problem! Since we know the graph, everything we'd want is merely a permutation on our graph.

** click ** 

Here is another snippet, and again ignore the syntax but know this is creating an OCI compliant image.

** click **

We set the command of the image to be our what-is-my-ip package.
-->

---
layout: center
---

````md magic-move
```console {all}
> nix build -f what-is-my-ip-docker.nix --print-out-paths
```

```console
> nix build -f what-is-my-ip-docker.nix --print-out-paths
/nix/store/vwlbi7m9123cm6kjy1skh4fskh02c5zc-docker-image-what-is-my-ip-docker.tar.gz
```

```console
> nix build -f what-is-my-ip-docker.nix --print-out-paths
/nix/store/vwlbi7m9123cm6kjy1skh4fskh02c5zc-docker-image-what-is-my-ip-docker.tar.gz

> docker load /nix/store/vwlbi7m9123cm6kjy1skh4fskh02c5zc-docker-image-what-is-my-ip-docker.tar.gz
Loaded image: what-is-my-ip-docker:vwlbi7m9123cm6kjy1skh4fskh02c5zc
```

```console
> nix build -f what-is-my-ip-docker.nix --print-out-paths
/nix/store/vwlbi7m9123cm6kjy1skh4fskh02c5zc-docker-image-what-is-my-ip-docker.tar.gz

> docker load /nix/store/vwlbi7m9123cm6kjy1skh4fskh02c5zc-docker-image-what-is-my-ip-docker.tar.gz
Loaded image: what-is-my-ip-docker:vwlbi7m9123cm6kjy1skh4fskh02c5zc

> docker run -it what-is-my-ip-docker:vwlbi7m9123cm6kjy1skh4fskh02c5zc
73.231.52.39
```

```console
> nix build -f what-is-my-ip-docker.nix --print-out-paths
/nix/store/vwlbi7m9123cm6kjy1skh4fskh02c5zc-docker-image-what-is-my-ip-docker.tar.gz

> docker load /nix/store/vwlbi7m9123cm6kjy1skh4fskh02c5zc-docker-image-what-is-my-ip-docker.tar.gz
Loaded image: what-is-my-ip-docker:vwlbi7m9123cm6kjy1skh4fskh02c5zc

> docker run -it what-is-my-ip-docker:vwlbi7m9123cm6kjy1skh4fskh02c5zc
73.231.52.39

> docker inspect what-is-my-ip-docker:vwlbi7m9123cm6kjy1skh4fskh02c5zc --format "{{.Config.Cmd}}"
[/nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip]
```
````

Remember <u>y2g0ijqqiyi9vxr9xgmvvgblxqflqzav</u>

<!--
Let's build the image.

** click ** 

The output is a OCI tarball.

** click ** 

We can load that tarball into the docker daemon as normal.

** click ** 

Running the tarball works as we'd expect as well.

** click ** 

Inspecting the image, we see yet again that same prefix hash on our package for the command to execute -- which continues to give us comfort about the
version and state of our software.
-->

---
layout: center
---

Cool ! 😎

Nix + Docker integration perfectly. The image produced has only the files exactly necessary to run the tool provided, <u>effectively distroless</u>.

You can do the same thing for any deployment format!

- oci images
- tarballs
- self-extracing ZIP
- rpm
- deb
- Flatpak / AppImage

---
layout: fact
---

A Linux distribution is simply a collection of packages.

<style>
p {
  font-size: 2em;
}
</style>

---
layout: center
---

````md magic-move
```nix {all|4,11-13|21|all}
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/5ef6c425980847c78a80d759abc476e941a9bf42.tar.gz";
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
```
````

---
layout: center
---

````md magic-move
```console
> nix build -f what-is-my-ip-vm.nix --print-out-paths
```

```console
> nix build -f what-is-my-ip-vm.nix --print-out-paths
/nix/store/k6vqp2hn0gh7r5dmc61f5knqgnqn53wz-nixos-vm
```

```console
> nix build -f what-is-my-ip-vm.nix --print-out-paths
/nix/store/k6vqp2hn0gh7r5dmc61f5knqgnqn53wz-nixos-vm

> QEMU_KERNEL_PARAMS=console=ttyS0 /nix/store/k6vqp2hn0gh7r5dmc61f5knqgnqn53wz-nixos-vm/bin/run-nixos-vm -nographic;reset
```

```console
> nix build -f what-is-my-ip-vm.nix --print-out-paths
/nix/store/k6vqp2hn0gh7r5dmc61f5knqgnqn53wz-nixos-vm

> QEMU_KERNEL_PARAMS=console=ttyS0 /nix/store/k6vqp2hn0gh7r5dmc61f5knqgnqn53wz-nixos-vm/bin/run-nixos-vm -nographic;reset

... long boot sequence ...

+++ Welcome to NixOS 24.11pre-git (x86_64) - ttyS0 +++

Run 'nixos-help' for the NixOS manual.

nixos login: alice
Password:
```

```console
> nix build -f what-is-my-ip-vm.nix --print-out-paths
/nix/store/k6vqp2hn0gh7r5dmc61f5knqgnqn53wz-nixos-vm

> QEMU_KERNEL_PARAMS=console=ttyS0 /nix/store/k6vqp2hn0gh7r5dmc61f5knqgnqn53wz-nixos-vm/bin/run-nixos-vm -nographic;reset

... long boot sequence ...

+++ Welcome to NixOS 24.11pre-git (x86_64) - ttyS0 +++

Run 'nixos-help' for the NixOS manual.

nixos login: alice
Password:

[alice@nixos:~]$ which what-is-my-ip
/etc/profiles/per-user/alice/bin/what-is-my-ip

[alice@nixos:~]$ realpath $(which what-is-my-ip)
/nix/store/y2g0ijqqiyi9vxr9xgmvvgblxqflqzav-what-is-my-ip/bin/what-is-my-ip

[alice@nixos:~]$ what-is-my-ip
73.231.52.39
```
````

Remember <u>y2g0ijqqiyi9vxr9xgmvvgblxqflqzav</u>

---
layout: end
---

Fin.

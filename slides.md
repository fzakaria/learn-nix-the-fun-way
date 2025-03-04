---
# You can also start simply with 'default'
theme: default

background: /nix-wallpaper-nineish-catppuccin-latte-alt.svg
# some information about your slides (markdown enabled)
title: Learn Nix the Fun Way
info: |
  This is a talk I am giving at [NixPlanet 2025](https://planetnix.com/)
  on _why you may want use Nix_.
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

---
transition: fade-out
layout: two-cols
---

# Hello 👋

My name is Farid Zakaria, and I'm a software engineer at [Confluent](https://www.confluent.io/) mostly working on Bazel and pursuing a nearly-complete PhD at UC Santa Cruz.

- "Long-time" Nix user (circa 2025)
- Introduced Nix at [Looker](https://cloud.google.com/looker) (purchased by Google) and active member of internal community
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
Here is another comment.
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

---
layout: center
---

````md magic-move
```nix {all}
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

---
layout: default
---

<p>
Seeing <code>y2g0ijqqiyi9vxr9xgmvvgblxqflqzav</code> means we have <i>extremely</i> strong guarantees of the software graph down to the commit and build instructions.
</p>

<img style="margin: auto; height: 400px; width: auto;" src="./images/denaziamigo-doggo.gif"/>

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

---
layout: center
---

<h3>Reproducible Developer Environments ✔️</h3>
<p>
  <img src="./images/boom-mind-blown.gif" />
</p>

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

---
layout: center
---

<h3>Binary (or source) Deployments ✔️</h3>
<p>
  <img src="./images/chris-pratt-mind-blown.gif" />
</p>

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

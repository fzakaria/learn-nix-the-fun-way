<script setup lang="ts">
const gitHash: string = GIT_HASH;
</script>
<template>
  <div class="git-commit">
    <a
      :href="`https://github.com/fzakaria/learn-nix-the-fun-way/commit/${gitHash}`"
      >{{ gitHash }}</a
    >
  </div>
</template>

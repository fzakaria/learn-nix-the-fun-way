import { defineConfig } from "vite";
import { execSync } from "child_process";

export default defineConfig({
  define: {
    GIT_HASH: JSON.stringify(execSync("git rev-parse HEAD").toString().trim()),
  },
});

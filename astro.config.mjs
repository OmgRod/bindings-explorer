import { defineConfig } from "astro/config"
import starlight from "@astrojs/starlight"
import starlightConfig from "./starlight.config.ts"

export default defineConfig({
  integrations: [starlight(starlightConfig)]
})

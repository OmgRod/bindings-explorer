import { defineConfig } from "astro/config"
import starlight from "@astrojs/starlight"
import starlightConfig from "./starlight.config.ts"
import mdx from "@astrojs/mdx"
import react from '@astrojs/react';

export default defineConfig({
  integrations: [
	  	starlight(starlightConfig),
	  	mdx(),
		react(),
	]
})

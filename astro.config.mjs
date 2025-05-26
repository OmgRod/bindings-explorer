import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import starlightConfig from "./starlight.config.ts";
import mdx from "@astrojs/mdx";
import react from "@astrojs/react";

export default defineConfig({
  site: 'https://omgrod.me',
  base: '/bindings-explorer', // ✅ moved here
  integrations: [
    starlight(starlightConfig),
    mdx(),
    react()
  ],
  starlight: {
    search: {
      provider: 'none' // ✅ moved here too
	  }
  },
});

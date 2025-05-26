import { defineConfig } from "astro/config";
import fs from "fs";
import path from "path";

interface SidebarItem {
  label: string;
  link: string;
}

interface SidebarGroup {
  label: string;
  items: SidebarItem[];
}

function toSlug(name: string): string {
  return name.replace(/[^a-zA-Z0-9\-]/g, "_");
}

function generateSidebar(): SidebarGroup[] {
  const versionsDir = path.resolve("./src/data/versions");
  let versions = fs.readdirSync(versionsDir);

  versions = versions.sort().reverse();

  return versions.map((version) => {
    const jsonPath = path.join(versionsDir, version, "codegen.json");
    const raw = fs.readFileSync(jsonPath, "utf-8");
    const data = JSON.parse(raw);

    const items: SidebarItem[] = data.classes
      .slice()
      .sort((a: any, b: any) => a.name.localeCompare(b.name))
      .map((cls: any) => ({
        label: cls.name,
        link: `/${version}/${toSlug(cls.name)}`
      }));

    return {
      label: `Version ${version}`,
      items,
    };
  });
}

export default defineConfig({
  title: "Geode Bindings Explorer",
  sidebar: generateSidebar(),
  tableOfContents: false,
  customCss: ["./src/assets/customCSS.css"],
  pagination: false,
  pagefind: false,
  logo: {
    light: './src/assets/logo-nav-light.png',
    dark: './src/assets/logo-nav-dark.png',
    replacesTitle: true,
  }
});

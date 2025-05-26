import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
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

function generateSidebar(): SidebarGroup[] {
  const versionsDir = path.resolve("./src/data/versions");
  const versions = fs.readdirSync(versionsDir);

  return versions.map((version) => {
    const jsonPath = path.join(versionsDir, version, "codegen.json");
    const raw = fs.readFileSync(jsonPath, "utf-8");
    const data = JSON.parse(raw);

    const items: SidebarItem[] = data.classes.map((cls: any) => ({
      label: cls.name,
      link: `/bindings/${version}/${cls.name}`
    }));

    return {
      label: `Version ${version}`,
      items,
    };
  });
}

export default defineConfig({
  integrations: [starlight({
    title: "Geode Bindings Explorer",
    sidebar: generateSidebar()
  })],
});

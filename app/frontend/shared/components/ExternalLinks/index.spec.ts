import { afterEach, describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

afterEach(() => {
  document.body.innerHTML = "";
});

const mount = async (title: string) => {
  const target = document.createElement("div");
  target.id = "header-right";
  document.body.appendChild(target);

  await mountWithDefaults(Component, {
    props: { title },
    attachTo: document.body,
  });

  return target;
};

describe("ExternalLinks", () => {
  it("searches the wiki and the Galactapedia for the name, in the header", async () => {
    const header = await mount(" Stanton System ");

    const wiki = header.querySelector("[data-test='wiki-link']");
    const galactapedia = header.querySelector(
      "[data-test='galactapedia-link']",
    );

    expect(wiki?.getAttribute("href")).toBe(
      "https://starcitizen.tools/index.php?title=Special:Search&go=Go&search=Stanton%20System",
    );
    expect(galactapedia?.getAttribute("href")).toBe(
      "https://robertsspaceindustries.com/galactapedia/search?query=Stanton%20System",
    );
  });
});

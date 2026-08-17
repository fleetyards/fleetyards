import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

describe("Markdown", () => {
  const mount = (source: string) =>
    mountWithDefaults<typeof Component>(Component, { props: { source } });

  it("renders headings two levels down", async () => {
    const wrapper = await mount("## Missing Models (2)");

    expect(wrapper.find("h4").text()).toBe("Missing Models (2)");
  });

  it("groups consecutive items into one list", async () => {
    const wrapper = await mount("- **Aurora MR**\n- Carrack");

    expect(wrapper.findAll("ul")).toHaveLength(1);
    expect(wrapper.findAll("li")).toHaveLength(2);
    expect(wrapper.find("li strong").text()).toBe("Aurora MR");
  });

  it("renders inline code", async () => {
    const wrapper = await mount("Add it to `MAPPINGS`.");

    expect(wrapper.find("code").text()).toBe("MAPPINGS");
  });

  it("splits paragraphs on blank lines", async () => {
    const wrapper = await mount("First report.\n\nSecond report.");

    expect(wrapper.findAll("p")).toHaveLength(2);
  });

  it("escapes html in the source", async () => {
    const wrapper = await mount("<img src=x onerror=alert(1)>");

    expect(wrapper.find("img").exists()).toBe(false);
    expect(wrapper.text()).toContain("<img src=x onerror=alert(1)>");
  });

  it("links only http and same-origin targets", async () => {
    const wrapper = await mount(
      "[report](https://fleetyards.net) and [nope](javascript:alert(1))",
    );

    expect(wrapper.find("a").attributes("href")).toBe("https://fleetyards.net");
    expect(wrapper.findAll("a")).toHaveLength(1);
    expect(wrapper.text()).toContain("[nope](javascript:alert(1))");
  });
});

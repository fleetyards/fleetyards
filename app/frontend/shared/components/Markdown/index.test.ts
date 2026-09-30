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

  it("renders italic, also around bold", async () => {
    const wrapper = await mount("*since **2950***");

    expect(wrapper.find("em").text()).toBe("since 2950");
    expect(wrapper.find("em strong").text()).toBe("2950");
  });

  it("leaves a list marker and a lone asterisk as they are", async () => {
    const wrapper = await mount("* one\n\n2 * 3 = 6");

    expect(wrapper.find("li").text()).toBe("one");
    expect(wrapper.find("em").exists()).toBe(false);
    expect(wrapper.text()).toContain("2 * 3 = 6");
  });

  it("leaves a [*catalogue token*] for the token parser", async () => {
    const wrapper = await mount(
      "Fit a [*Attrition-3*] and [*equipment:Arden-SL*]",
    );

    expect(wrapper.find("em").exists()).toBe(false);
    expect(wrapper.text()).toContain("[*Attrition-3*]");
  });

  it("centres the lines inside a :::center block", async () => {
    const wrapper = await mount(
      ":::center\nWelcome to the **Crew**\n\nsince 2950\n:::\nAfter",
    );

    const centre = wrapper.find(".markdown__center");
    expect(centre.findAll("p")).toHaveLength(2);
    expect(centre.find("strong").text()).toBe("Crew");
    expect(centre.text()).not.toContain("After");
  });

  it("closes an unterminated :::center block and keeps a stray ::: as text", async () => {
    const wrapper = await mount(":::\n:::center\nWelcome");

    expect(wrapper.text()).toContain(":::");
    expect(wrapper.find(".markdown__center").text()).toBe("Welcome");
  });

  it("formats nothing inside inline code", async () => {
    const wrapper = await mount("Use `*value*` and `**x**`");

    expect(wrapper.find("em").exists()).toBe(false);
    expect(wrapper.find("strong").exists()).toBe(false);
    expect(wrapper.findAll("code").map((code) => code.text())).toEqual([
      "*value*",
      "**x**",
    ]);
  });

  it("keeps a refused image as text rather than a link", async () => {
    const wrapper = await mount("![cover](http://example.com/a.jpg)");

    expect(wrapper.find("a").exists()).toBe(false);
    expect(wrapper.text()).toContain("![cover](http://example.com/a.jpg)");
  });

  it("treats //host and /\\host as another origin", async () => {
    const wrapper = await mount(
      "[a](//evil.test) [b](/\\evil.test) [c](/fleets/maru) ![d](//evil.test/x.jpg)",
    );

    const links = wrapper.findAll("a");
    expect(links).toHaveLength(1);
    expect(links[0].attributes("href")).toBe("/fleets/maru");
    expect(wrapper.find("img").exists()).toBe(false);
  });

  it("shows a backslash-escaped character as itself, unformatted", async () => {
    const wrapper = await mount(
      "Some \\[REDACTED\\] and 2 \\* 3 \\* 4 and a\\_b",
    );

    expect(wrapper.text()).toBe("Some [REDACTED] and 2 * 3 * 4 and a_b");
    expect(wrapper.find("em").exists()).toBe(false);
  });

  it("keeps an escaped marker out of the formatting it would close", async () => {
    const wrapper = await mount("*Superior since **\\[REDACTED\\]***");

    expect(wrapper.find("em").text()).toBe("Superior since [REDACTED]");
    expect(wrapper.find("em strong").text()).toBe("[REDACTED]");
  });

  it("decodes entities without turning them into markup", async () => {
    const wrapper = await mount(
      "&lt;&lt; DAKKAR &gt;&gt; &amp; &#42;not italic&#42; &lt;img src=x onerror=alert(1)&gt;",
    );

    expect(wrapper.text()).toBe(
      "<< DAKKAR >> & *not italic* <img src=x onerror=alert(1)>",
    );
    expect(wrapper.find("em").exists()).toBe(false);
    expect(wrapper.find("img").exists()).toBe(false);
  });

  it("leaves an unknown entity and escapes inside code as written", async () => {
    const wrapper = await mount("&bogus; and `a\\_b &amp;`");

    expect(wrapper.text()).toContain("&bogus;");
    expect(wrapper.find("code").text()).toBe("a\\_b &amp;");
  });

  it("ignores a placeholder character typed into the text", async () => {
    const wrapper = await mount("a\ue000\ue105b \\*");

    expect(wrapper.text()).toBe("a\ue105b *");
  });

  it("renders numbered lists, keeping where they start", async () => {
    const wrapper = await mount("1. Download\n2. Import\n\n3) Share\n- bullet");

    const lists = wrapper.findAll("ol");
    expect(lists).toHaveLength(2);
    expect(lists[0].findAll("li")).toHaveLength(2);
    expect(lists[0].attributes("start")).toBeUndefined();
    expect(lists[1].attributes("start")).toBe("3");
    expect(wrapper.find("ul li").text()).toBe("bullet");
  });

  it("reads a line of = or - under a paragraph as its heading", async () => {
    const wrapper = await mount("History\n-----------\nText\n\nFleet\n===");

    expect(wrapper.find("h4").text()).toBe("History");
    expect(wrapper.find("h3").text()).toBe("Fleet");
    expect(wrapper.find("p").text()).toBe("Text");
  });

  it("draws a rule for a line of three or more markers on its own", async () => {
    const wrapper = await mount("Above\n\n---\n\nBelow\n\n* * *");

    expect(wrapper.findAll("hr")).toHaveLength(2);
    expect(wrapper.find("h4").exists()).toBe(false);
  });

  it("takes + as a bullet too", async () => {
    const wrapper = await mount("+ one\n+ two");

    expect(wrapper.findAll("ul li")).toHaveLength(2);
  });

  it("renders https images only", async () => {
    const wrapper = await mount(
      "![cover](https://robertsspaceindustries.com/cover.jpg) ![x](http://example.com/a.jpg) ![y](javascript:alert(1))",
    );

    const images = wrapper.findAll("img");
    expect(images).toHaveLength(1);
    expect(images[0].attributes("src")).toBe(
      "https://robertsspaceindustries.com/cover.jpg",
    );
    expect(images[0].attributes("alt")).toBe("cover");
  });

  it("keeps an image source from breaking out of its attribute", async () => {
    const wrapper = await mount('![a](https://x.test/"onerror="alert(1))');

    expect(wrapper.find("img").attributes("onerror")).toBeUndefined();
  });
});

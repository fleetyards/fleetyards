import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

// Images load only from the hosts the page names as its own and RSI's.
window.API_ENDPOINT = "https://api.fleetyards.test/v1";
window.FRONTEND_ENDPOINT = "https://fleetyards.test";
window.RSI_ENDPOINT = "https://robertsspaceindustries.com";

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

  it("marks a catalogue token with its name, not as emphasis", async () => {
    const wrapper = await mount(
      "Fit a [*Attrition-3 Repeater*] and [*equipment:Arden-SL Core*]",
    );

    const marks = wrapper.findAll("[data-catalogue-token]");
    expect(
      marks.map((mark) => mark.attributes("data-catalogue-token")),
    ).toEqual(["Attrition-3 Repeater", "equipment:Arden-SL Core"]);
    expect(wrapper.text()).toBe("Fit a Attrition-3 Repeater and Arden-SL Core");
    expect(wrapper.find("em").exists()).toBe(false);
  });

  it("formats nothing inside a token, its attribute included", async () => {
    const wrapper = await mount("[*Mk ~~2~~ Rifle*] and ~~gone~~");

    const mark = wrapper.find("[data-catalogue-token]");
    expect(mark.attributes("data-catalogue-token")).toBe("Mk ~~2~~ Rifle");
    expect(mark.find("del").exists()).toBe(false);
    expect(wrapper.find("del").text()).toBe("gone");
  });

  it("leaves a token inside code as written", async () => {
    const wrapper = await mount("Type `[*Name*]` to name an item");

    expect(wrapper.find("[data-catalogue-token]").exists()).toBe(false);
    expect(wrapper.find("code").text()).toBe("[*Name*]");
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

  it("links an image from a host the page may not load", async () => {
    const wrapper = await mount(
      "![cover](https://imgur.test/a.jpg) ![](https://imgur.test/b.jpg)",
    );

    expect(wrapper.find("img").exists()).toBe(false);
    const links = wrapper.findAll("a");
    expect(links.map((link) => link.text())).toEqual([
      "cover",
      "https://imgur.test/b.jpg",
    ]);
    expect(links[0].attributes("href")).toBe("https://imgur.test/a.jpg");
  });

  it("keeps an image that is neither loadable nor linkable as text", async () => {
    const wrapper = await mount("![cover](javascript:alert(1))");

    expect(wrapper.find("a").exists()).toBe(false);
    expect(wrapper.text()).toContain("![cover](javascript:alert(1))");
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

  it("nests a list by its indentation", async () => {
    const wrapper = await mount(
      "- Ships\n  - Aurora\n  - Carrack\n- Crew\n  1. Pilot\n  2. Gunner",
    );

    const top = wrapper.find("ul");
    expect(top.element.children).toHaveLength(2);
    expect(top.findAll(":scope > li > ul > li").map((li) => li.text())).toEqual(
      ["Aurora", "Carrack"],
    );
    expect(top.findAll(":scope > li > ol > li")).toHaveLength(2);
  });

  it("renders a quote with markdown of its own", async () => {
    const wrapper = await mount("> **Meet** at\n> - Olisar\n\nAfter");

    expect(wrapper.find("blockquote strong").text()).toBe("Meet");
    expect(wrapper.find("blockquote li").text()).toBe("Olisar");
    expect(wrapper.find("p:last-child").text()).toBe("After");
  });

  it("renders fenced code as written", async () => {
    const wrapper = await mount("```\n**not bold** <b>\n  indented\n```");

    expect(wrapper.find("pre code").text()).toBe(
      "**not bold** <b>\n  indented",
    );
    expect(wrapper.find("strong").exists()).toBe(false);
  });

  it("strikes through ~~text~~", async () => {
    const wrapper = await mount("~~cancelled~~ moved");

    expect(wrapper.find("del").text()).toBe("cancelled");
  });

  it("reads escaped backticks as backticks, not a code span", async () => {
    const wrapper = await mount("literal \\`ship\\` and `real`");

    expect(wrapper.text()).toBe("literal `ship` and real");
    expect(wrapper.findAll("code")).toHaveLength(1);
    expect(wrapper.find("code").text()).toBe("real");
  });

  it("judges a link by its address once escapes and entities are read", async () => {
    const wrapper = await mount(
      "[a](/\\/evil.test) [b](/&#47;evil.test) [c](/&#92;evil.test) ![d](/\\/evil.test/x.jpg) [ok](/fleets/maru)",
    );

    const links = wrapper.findAll("a");
    expect(links).toHaveLength(1);
    expect(links[0].attributes("href")).toBe("/fleets/maru");
    expect(wrapper.find("img").exists()).toBe(false);
  });

  it("links an escaped character in an address as that character", async () => {
    const wrapper = await mount(
      "[wiki](https://example.org/Ship\\_\\(game\\))",
    );

    expect(wrapper.find("a").attributes("href")).toBe(
      "https://example.org/Ship_(game)",
    );
  });

  it("keeps a code block inside its list item", async () => {
    const wrapper = await mount(
      "- Join with\n\n  ```\n  /join *fleet*\n  ```\n- Then wait",
    );

    const items = wrapper.findAll("ul > li");
    expect(items).toHaveLength(2);
    expect(items[0].find("pre code").text()).toBe("/join *fleet*");
    expect(wrapper.find("em").exists()).toBe(false);
  });

  it("does not end a code block on a line that only starts like a fence", async () => {
    const wrapper = await mount("```\n```still-code\n**second**\n```\nAfter");

    expect(wrapper.find("pre code").text()).toBe("```still-code\n**second**");
    expect(wrapper.find("strong").exists()).toBe(false);
    expect(wrapper.find("p").text()).toBe("After");
  });

  it("shows an image whose description has brackets", async () => {
    const wrapper = await mount(
      "![Fleet [Alpha]](https://robertsspaceindustries.com/a.jpg) [Team [A]](/fleets/a)",
    );

    expect(wrapper.find("img").attributes("alt")).toBe("Fleet [Alpha]");
    expect(wrapper.find("a").text()).toBe("Team [A]");
  });

  it("renders images from Fleetyards and RSI only", async () => {
    const wrapper = await mount(
      "![cover](https://robertsspaceindustries.com/cover.jpg) ![up](https://api.fleetyards.test/files/a.webp) ![here](/files/b.webp) ![x](https://imgur.test/a.jpg) ![y](http://robertsspaceindustries.com/c.jpg)",
    );

    expect(wrapper.findAll("img").map((img) => img.attributes("src"))).toEqual([
      "https://robertsspaceindustries.com/cover.jpg",
      "https://api.fleetyards.test/files/a.webp",
      "/files/b.webp",
    ]);
    expect(wrapper.find("img").attributes("alt")).toBe("cover");
  });

  it("sizes an image only to the steps it knows", async () => {
    const wrapper = await mount(
      "![a](https://robertsspaceindustries.com/a.jpg){width=50%} ![b](https://robertsspaceindustries.com/b.jpg){width=33%}",
    );

    const images = wrapper.findAll("img");
    expect(images[0].attributes("data-size")).toBe("50");
    expect(images[1].attributes("data-size")).toBeUndefined();
    expect(wrapper.text()).toContain("{width=33%}");
  });

  it("refuses an image with the page's origin but another scheme", async () => {
    const wrapper = await mount("![b](blob:https://fleetyards.test/1234)");

    expect(wrapper.find("img").exists()).toBe(false);
  });

  it("keeps an image source from breaking out of its attribute", async () => {
    const wrapper = await mount(
      '![a](https://robertsspaceindustries.com/"onerror="alert(1))',
    );

    expect(wrapper.find("img").exists()).toBe(true);
    expect(wrapper.find("img").attributes("onerror")).toBeUndefined();
  });
});

import { Editor } from "@tiptap/core";
import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Markdown from "@/shared/components/Markdown/index.vue";
import { markdownExtensions, protectHtml, toMarkdown } from "./extensions";

const load = (markdown: string) =>
  new Editor({
    extensions: markdownExtensions(),
    content: protectHtml(markdown),
    contentType: "markdown",
  });

const roundTrip = (markdown: string) => {
  const editor = load(markdown);
  const result = toMarkdown(editor);
  editor.destroy();
  return result;
};

const render = async (markdown: string) =>
  (
    await mountWithDefaults<typeof Markdown>(Markdown, {
      props: { source: markdown },
    })
  ).find(".markdown");

// Every node the toolbar can produce, and every one a stored description
// already carries, has to come back from the editor as the same markdown --
// otherwise opening and saving a description would rewrite it.
describe("markdownExtensions round trip", () => {
  it.each([
    ["paragraphs and soft line breaks", "Line one\nLine two\n\nNext"],
    ["bold, italic and code", "**bold**, *italic* and `code`"],
    ["headings", "# One\n\n## Two\n\n### Three"],
    ["a bulleted list", "- **Aurora** MR\n- Carrack"],
    ["a numbered list", "1. Download\n2. Import"],
    ["a link", "[The Fleet](https://fleetyards.net/fleets/maru/ships/)"],
    ["a same-origin link", "[Stats](/fleets/maru/stats/)"],
    ["an image", "![](https://robertsspaceindustries.com/cover.jpg)"],
    [
      "an image with a description",
      "![Fleet cover](https://robertsspaceindustries.com/cover.jpg)",
    ],
    ["a rule", "Above\n\n---\n\nBelow"],
    ["a hard break", "Line one  \nhard break"],
    ["a quote", "> Quoted instructions\n\nAfter"],
    ["a strike", "~~cancelled~~ moved"],
    ["a fenced code block", "```\n/join fleet\n```"],
    ["a nested list", "- Ships\n  - Aurora\n  - Carrack\n- Crew"],
  ])("keeps %s", (_, markdown) => {
    expect(roundTrip(markdown)).toBe(markdown);
  });

  it("keeps a centre block, with the blank lines it writes inside", () => {
    const stored = ":::center\nWelcome to the\n**Crew**\n:::\n\nMore";
    const saved = roundTrip(stored);

    expect(saved).toBe(":::center\n\nWelcome to the\n**Crew**\n\n:::\n\nMore");
    expect(roundTrip(saved)).toBe(saved);
  });

  it("writes an underlined heading as a # heading of the same level", () => {
    expect(roundTrip("History\n-------\n\nText")).toBe("## History\n\nText");
  });
});

// What the editor writes is what the page shows: no stray backslash or entity
// name, and the same structure.
describe("markdownExtensions output rendered by Markdown", () => {
  it("shows escaped characters as themselves", async () => {
    const saved = roundTrip("Some [REDACTED] & 2 * 3 << DAKKAR >> a_b");
    const rendered = await render(saved);

    expect(saved).not.toBe("Some [REDACTED] & 2 * 3 << DAKKAR >> a_b");
    expect(rendered.text()).toBe("Some [REDACTED] & 2 * 3 << DAKKAR >> a_b");
    expect(rendered.find("em").exists()).toBe(false);
  });

  it("renders a saved centre block centred", async () => {
    const rendered = await render(roundTrip(":::center\nWelcome\n:::"));

    expect(rendered.find(".markdown__center p").text()).toBe("Welcome");
  });

  it("renders a saved quote, strike, code block and nested list", async () => {
    const rendered = await render(
      roundTrip(
        "> Quoted\n\n~~gone~~\n\n```\n/join *fleet*\n```\n\n- Ships\n  - Aurora\n- Crew",
      ),
    );

    expect(rendered.find("blockquote").text()).toBe("Quoted");
    expect(rendered.find("del").text()).toBe("gone");
    expect(rendered.find("pre code").text()).toBe("/join *fleet*");
    expect(rendered.find("ul > li > ul > li").text()).toBe("Aurora");
    expect(rendered.findAll("ul")[0].element.children).toHaveLength(2);
  });

  it("renders saved lists, headings and emphasis", async () => {
    const rendered = await render(
      roundTrip("## Crew\n\n1. **Download**\n2. *Import*\n\n- bullet"),
    );

    expect(rendered.find("h4").text()).toBe("Crew");
    expect(rendered.findAll("ol li")).toHaveLength(2);
    expect(rendered.find("ol strong").text()).toBe("Download");
    expect(rendered.find("ol em").text()).toBe("Import");
    expect(rendered.find("ul li").text()).toBe("bullet");
  });
});

describe("markdownExtensions and angle brackets", () => {
  it("keeps typed <text> instead of dropping it as a tag", async () => {
    const saved = roundTrip("Ask <RSI handle> or <b>us</b>, not `<code>`");
    const rendered = await render(saved);

    expect(rendered.text()).toBe("Ask <RSI handle> or <b>us</b>, not <code>");
    expect(rendered.find("code").text()).toBe("<code>");
    expect(rendered.find("b").exists()).toBe(false);
  });

  it("leaves angle brackets inside fenced code in a quote or list alone", async () => {
    expect(protectHtml("> ```\n> <tag>\n> ```\n> <tag>")).toBe(
      "> ```\n> <tag>\n> ```\n> &lt;tag>",
    );
    expect(protectHtml("- item\n\n  ```\n  <tag>\n  ```")).toBe(
      "- item\n\n  ```\n  <tag>\n  ```",
    );

    const rendered = await render(roundTrip("> ```\n> <tag>\n> ```"));
    expect(rendered.find("blockquote pre code").text()).toBe("<tag>");
  });

  it("keeps a fence open past a line that only starts like one", () => {
    expect(protectHtml("```\n```x <a>\n```\n<a>")).toBe(
      "```\n```x <a>\n```\n&lt;a>",
    );
  });

  it("leaves angle brackets inside fenced code alone", () => {
    expect(protectHtml("```\n<tag>\n```\n<tag>")).toBe(
      "```\n<tag>\n```\n&lt;tag>",
    );
  });
});

describe("markdownExtensions links from the toolbar", () => {
  it("renders a link whose text has brackets", async () => {
    const editor = load("");
    editor.commands.insertContent({
      type: "text",
      text: "Team [A]",
      marks: [{ type: "link", attrs: { href: "https://fleetyards.net/" } }],
    });
    const rendered = await render(toMarkdown(editor));
    editor.destroy();

    expect(rendered.find("a").text()).toBe("Team [A]");
    expect(rendered.find("a").attributes("href")).toBe(
      "https://fleetyards.net/",
    );
  });
});

describe("markdownExtensions images", () => {
  it("renders an image whose description has brackets as an image", async () => {
    const editor = load("");
    editor.commands.setImage({
      src: "https://robertsspaceindustries.com/a.jpg",
      alt: "Fleet [Alpha]",
    });
    const rendered = await render(toMarkdown(editor));
    editor.destroy();

    expect(rendered.find("img").attributes("alt")).toBe("Fleet [Alpha]");
  });

  it("keeps numbered lists nested where the editor put them", async () => {
    const rendered = await render(
      roundTrip("1. Crew\n   1. Pilot\n   2. Gunner\n2. Ships\n   - Aurora"),
    );

    expect(rendered.findAll("ol > li > ol > li")).toHaveLength(2);
    expect(rendered.find("ol > li > ul > li").text()).toBe("Aurora");
    expect(rendered.find("ol").element.children).toHaveLength(2);
  });

  it("keeps a code block inside a list item where the editor put it", async () => {
    const rendered = await render(
      roundTrip("- Join with\n\n  ```\n  /join\n  ```\n\n- Then wait"),
    );

    expect(rendered.find("ul > li pre code").text()).toBe("/join");
  });
});

describe("markdownExtensions refusals", () => {
  it("drops a pasted image the page would not show", () => {
    const editor = load("");
    editor.commands.setContent(
      '<p>a</p><img src="http://insecure.test/a.jpg"><img src="https://ok.test/b.jpg">',
    );

    expect(toMarkdown(editor)).toBe("a\n\n![](https://ok.test/b.jpg)");
    editor.destroy();
  });

  it("drops a pasted javascript: link but keeps its text", () => {
    const editor = load("");
    editor.commands.setContent(
      '<p><a href="javascript:alert(1)">click</a></p>',
    );

    expect(toMarkdown(editor)).toBe("click");
    editor.destroy();
  });
});

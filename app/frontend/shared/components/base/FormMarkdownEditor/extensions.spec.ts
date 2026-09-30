import { Editor } from "@tiptap/core";
import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Markdown from "@/shared/components/Markdown/index.vue";
import { markdownExtensions, toMarkdown } from "./extensions";

const load = (markdown: string) =>
  new Editor({
    extensions: markdownExtensions(),
    content: markdown,
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
    ["a rule", "Above\n\n---\n\nBelow"],
    ["a hard break", "Line one  \nhard break"],
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

  it("turns a quote and a strike into plain text", () => {
    expect(roundTrip("> quote")).toBe("quote");
    expect(roundTrip("~~strike~~")).toBe("strike");
  });
});

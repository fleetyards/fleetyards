import { describe, expect, it } from "vitest";
import { markdownToPlainText, renderMarkdown } from "./Markdown";

describe("markdownToPlainText", () => {
  it("drops the markup and keeps the words", () => {
    expect(
      markdownToPlainText(
        "## Briefing\n\n**Meet** at *Port Olisar*\n\n- one\n- two\n\n[Map](https://x.test)",
      ),
    ).toBe("Briefing Meet at Port Olisar one two Map");
  });

  it("reads escapes and entities as the characters they stand for", () => {
    expect(markdownToPlainText("Some \\[REDACTED\\] &amp; 2 \\* 3")).toBe(
      "Some [REDACTED] & 2 * 3",
    );
  });

  it("keeps a line break as a space", () => {
    expect(markdownToPlainText("Line one\nLine two")).toBe("Line one Line two");
  });

  it("leaves markup-looking text as text", () => {
    expect(markdownToPlainText("<img src=x onerror=alert(1)>")).toBe(
      "<img src=x onerror=alert(1)>",
    );
  });

  it("reads a catalogue token as the item's name", () => {
    expect(
      markdownToPlainText(
        "Fit [*Attrition-3 Repeater*] or [*commodity:Mercury*]",
      ),
    ).toBe("Fit Attrition-3 Repeater or Mercury");
  });

  it("keeps a details summary apart from its body", () => {
    expect(
      markdownToPlainText(
        "<details>\n<summary>Loadout</summary>\n\nTwo repeaters\n</details>",
      ),
    ).toBe("Loadout Two repeaters");
  });

  it("gives nothing for an empty source", () => {
    expect(markdownToPlainText("")).toBe("");
  });
});

describe("renderMarkdown details", () => {
  it("renders a summary inline and the body as markdown", () => {
    expect(
      renderMarkdown(
        "Before\n<details>\n<summary>**Loadout** for *ops*</summary>\n\n- Repeater\n- Missiles\n\n</details>\nAfter",
      ),
    ).toBe(
      "<p>Before</p><details><summary><strong>Loadout</strong> for <em>ops</em></summary><ul><li>Repeater</li><li>Missiles</li></ul></details><p>After</p>",
    );
  });

  it("reads a summary on the opening line, and drops open", () => {
    expect(
      renderMarkdown(
        "<details open><summary>Crew</summary>\nThree pilots\n</details>",
      ),
    ).toBe("<details><summary>Crew</summary><p>Three pilots</p></details>");
  });

  it("reads a summary after blank lines", () => {
    expect(
      renderMarkdown(
        "<details>\n\n<summary>Crew</summary>\n\nBody\n</details>",
      ),
    ).toBe("<details><summary>Crew</summary><p>Body</p></details>");
  });

  it("leaves the summary out when there is none", () => {
    expect(renderMarkdown("<details>\n\nBody\n\n</details>")).toBe(
      "<details><p>Body</p></details>",
    );
  });

  it("nests sections", () => {
    expect(
      renderMarkdown(
        "<details>\n<summary>Outer</summary>\n\n<details>\n<summary>Inner</summary>\n\nDeep\n\n</details>\n\nTail\n\n</details>",
      ),
    ).toBe(
      "<details><summary>Outer</summary><details><summary>Inner</summary><p>Deep</p></details><p>Tail</p></details>",
    );
  });

  it("ignores the tags inside fenced code", () => {
    expect(
      renderMarkdown(
        "<details>\n<summary>Code</summary>\n\n```\n</details>\n```\n\n</details>",
      ),
    ).toBe(
      "<details><summary>Code</summary><pre><code>&lt;/details&gt;</code></pre></details>",
    );
  });

  it("runs a section left open to the end", () => {
    expect(renderMarkdown("<details>\n<summary>Open</summary>\nRest")).toBe(
      "<details><summary>Open</summary><p>Rest</p></details>",
    );
  });

  it("escapes markup in the summary and keeps other tags as text", () => {
    expect(
      renderMarkdown(
        "<details>\n<summary><img src=x onerror=alert(1)></summary>\n</details>\n<div>x</div>",
      ),
    ).toBe(
      "<details><summary>&lt;img src=x onerror=alert(1)&gt;</summary></details><p>&lt;div&gt;x&lt;/div&gt;</p>",
    );
  });

  it("keeps a stray closing tag as text", () => {
    expect(renderMarkdown("</details>")).toBe("<p>&lt;/details&gt;</p>");
  });
});

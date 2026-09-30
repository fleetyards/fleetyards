import { describe, expect, it } from "vitest";
import { markdownToPlainText } from "./Markdown";

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

  it("gives nothing for an empty source", () => {
    expect(markdownToPlainText("")).toBe("");
  });
});

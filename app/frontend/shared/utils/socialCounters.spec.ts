import { describe, expect, it } from "vitest";
import { blueskyLength, discordLength, xLength } from "./socialCounters";

/*
 * Pinned against the same cases as Announcements::Platform in Ruby. If these
 * two ever disagree, the editor shows an author a number the dry run and the
 * platform both contradict.
 */
describe("socialCounters", () => {
  it.each([
    ["latin", "abcdefghij", 10, 10],
    // X weights CJK at two; Bluesky counts one grapheme each.
    ["CJK", "公告测试内容", 12, 6],
    ["rocket emoji", "🚀", 2, 1],
    ["heart with variation selector", "❤️", 2, 1],
    ["ZWJ family", "👨‍👩‍👧", 2, 1],
    // X bills any URL at 23 regardless of length; Bluesky counts it in full.
    ["a URL", "a https://fleetyards.net/a/very/long/path", 2 + 23, 2 + 39],
    // X's extractor stops before trailing punctuation, so the full stop is
    // text rather than free inside the 23.
    [
      "a URL with a trailing full stop",
      "Read https://fleetyards.net.",
      5 + 23 + 1,
      28,
    ],
    // A URL ends at the first character RFC 3986 does not allow. CJK needs no
    // space before it, so `\S+` swallowed it into the flat 23.
    [
      "CJK straight after a URL",
      "https://fleetyards.net公告公告",
      23 + 8,
      22 + 4,
    ],
    ["empty", "", 0, 0],
  ])("counts %s", (_name, text, x, bluesky) => {
    expect(xLength(text as string)).toBe(x);
    expect(blueskyLength(text as string)).toBe(bluesky);
  });

  // Discord counts UTF-16 code units, so anything above the BMP costs two.
  it("counts Discord in UTF-16 code units", () => {
    expect(discordLength("🚀".repeat(10))).toBe(20);
    expect(discordLength("a".repeat(10))).toBe(10);
    expect(discordLength("公告")).toBe(2);
  });

  // The ellipsis sits outside X's light ranges, so it weighs two there.
  it("weighs the ellipsis the way X does", () => {
    expect(xLength("…")).toBe(2);
    expect(blueskyLength("…")).toBe(1);
  });
});

import { describe, expect, it } from "vitest";
import { blueskyLength, discordLength } from "./socialCounters";

/*
 * Pinned against the same cases as Announcements::Platform in Ruby. If these
 * two ever disagree, the editor shows an author a number the dry run and the
 * platform both contradict.
 */
describe("socialCounters", () => {
  it.each([
    ["latin", "abcdefghij", 10],
    ["CJK", "公告测试内容", 6],
    ["rocket emoji", "🚀", 1],
    ["heart with variation selector", "❤️", 1],
    ["ZWJ family", "👨‍👩‍👧", 1],
    ["a URL", "a https://fleetyards.net/a/very/long/path", 2 + 39],
    ["an ellipsis", "…", 1],
    ["empty", "", 0],
  ])("counts %s", (_name, text, bluesky) => {
    expect(blueskyLength(text as string)).toBe(bluesky);
  });

  // Discord counts UTF-16 code units, so anything above the BMP costs two.
  it("counts Discord in UTF-16 code units", () => {
    expect(discordLength("🚀".repeat(10))).toBe(20);
    expect(discordLength("a".repeat(10))).toBe(10);
    expect(discordLength("公告")).toBe(2);
  });
});

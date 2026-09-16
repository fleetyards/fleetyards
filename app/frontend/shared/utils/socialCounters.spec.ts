import { describe, expect, it } from "vitest";
import { blueskyLength, xLength } from "./socialCounters";

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
    ["empty", "", 0, 0],
  ])("counts %s", (_name, text, x, bluesky) => {
    expect(xLength(text as string)).toBe(x);
    expect(blueskyLength(text as string)).toBe(bluesky);
  });

  // The ellipsis sits outside X's light ranges, so it weighs two there.
  it("weighs the ellipsis the way X does", () => {
    expect(xLength("…")).toBe(2);
    expect(blueskyLength("…")).toBe(1);
  });
});

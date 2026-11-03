import { describe, expect, it } from "vitest";
import type { Component } from "@/services/fyApi";
import { compareItemImageFit } from "./image";

const item = (media: object) => ({ media }) as unknown as Component;
const file = { mediumUrl: "/picture.png" };

describe("compareItemImageFit", () => {
  it("contains an angled render, which stands on a transparent ground", () => {
    expect(compareItemImageFit(item({ angledView: file }))).toBe("contain");
    expect(
      compareItemImageFit(item({ angledView: file, storeImage: file })),
    ).toBe("contain");
  });

  it("covers with a store image, which is a full picture of its own", () => {
    expect(compareItemImageFit(item({ storeImage: file }))).toBe("cover");
  });

  it("does not take a missing picture for a render", () => {
    expect(compareItemImageFit(item({}))).toBe("cover");
  });
});

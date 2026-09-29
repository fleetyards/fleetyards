import { describe, expect, it } from "vitest";
import { arMode } from "./arViewer";

const anchor = (supportsAr: boolean) =>
  ({
    relList: { supports: (token: string) => supportsAr && token === "ar" },
  }) as unknown as HTMLAnchorElement;

describe("arMode", () => {
  it("offers Quick Look where the browser announces it", () => {
    expect(arMode("Mozilla/5.0 (iPhone)", anchor(true))).toBe("quick-look");
  });

  it("offers Scene Viewer on Android", () => {
    expect(arMode("Mozilla/5.0 (Linux; Android 14)", anchor(false))).toBe(
      "scene-viewer",
    );
  });

  it("offers nothing on a desktop", () => {
    expect(
      arMode("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0)", anchor(false)),
    ).toBeUndefined();
  });
});

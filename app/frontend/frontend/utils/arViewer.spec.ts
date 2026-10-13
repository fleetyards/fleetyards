import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mayHaveAr, openQuickLook, usesQuickLook } from "./arViewer";

vi.mock("@/frontend/utils/usdz", () => ({
  holoToUsdz: vi.fn(async () => new Blob(["usdz"])),
}));

const anchor = (supportsAr: boolean) =>
  ({
    relList: { supports: (token: string) => supportsAr && token === "ar" },
  }) as unknown as HTMLAnchorElement;

describe("mayHaveAr", () => {
  it("expects AR where the browser announces Quick Look", () => {
    expect(mayHaveAr("Mozilla/5.0 (iPhone)", anchor(true))).toBe(true);
  });

  it("expects AR on Android", () => {
    expect(mayHaveAr("Mozilla/5.0 (Linux; Android 14)", anchor(false))).toBe(
      true,
    );
  });

  it("does not expect AR on a desktop", () => {
    expect(
      mayHaveAr("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0)", anchor(false)),
    ).toBe(false);
  });
});

describe("usesQuickLook", () => {
  it("answers for a browser that announces Quick Look", () => {
    expect(usesQuickLook(anchor(true))).toBe(true);
  });

  it("does not answer for one that does not", () => {
    expect(usesQuickLook(anchor(false))).toBe(false);
  });
});

describe("openQuickLook", () => {
  const clicked: HTMLAnchorElement[] = [];
  let createObjectURL: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    clicked.length = 0;
    vi.spyOn(HTMLAnchorElement.prototype, "click").mockImplementation(function (
      this: HTMLAnchorElement,
    ) {
      clicked.push(this);
    });
    createObjectURL = vi
      .spyOn(URL, "createObjectURL")
      .mockReturnValue("blob:holo");
    vi.spyOn(URL, "revokeObjectURL").mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("hands the converted holo to Quick Look at true size", async () => {
    await openQuickLook("https://fleetyards.test/files/holo.glb");

    expect(clicked).toHaveLength(1);
    expect(clicked[0].rel).toBe("ar");
    expect(clicked[0].getAttribute("href")).toBe(
      "blob:holo#allowsContentScaling=0",
    );
    expect(clicked[0].querySelector("img")).not.toBeNull();
  });

  it("opens nothing for a holo no longer wanted once converted", async () => {
    await openQuickLook("https://fleetyards.test/files/holo.glb", () => false);

    expect(clicked).toHaveLength(0);
    expect(createObjectURL).not.toHaveBeenCalled();
  });
});

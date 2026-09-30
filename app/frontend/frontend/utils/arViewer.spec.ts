import { describe, expect, it } from "vitest";
import { mayHaveAr } from "./arViewer";

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

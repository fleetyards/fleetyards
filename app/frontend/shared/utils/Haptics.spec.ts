import { afterEach, describe, expect, it, vi } from "vitest";
import { hapticTick } from "./Haptics";

afterEach(() => {
  delete (navigator as Partial<Navigator>).vibrate;
});

describe("hapticTick", () => {
  it("vibrates briefly where the browser can", () => {
    const vibrate = vi.fn(() => true);
    Object.defineProperty(navigator, "vibrate", {
      value: vibrate,
      configurable: true,
    });

    hapticTick();

    expect(vibrate).toHaveBeenCalledWith(10);
  });

  it("stays silent where it cannot, as on iOS", () => {
    expect(() => hapticTick()).not.toThrow();
    expect(document.querySelector("input[switch]")).toBeNull();
  });
});

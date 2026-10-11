import { afterEach, describe, expect, it, vi } from "vitest";

afterEach(() => {
  vi.resetModules();
  vi.restoreAllMocks();
  document.body.innerHTML = "";
  delete (navigator as Partial<Navigator>).vibrate;
});

describe("hapticTick", () => {
  it("vibrates briefly where the browser can", async () => {
    const vibrate = vi.fn(() => true);
    Object.defineProperty(navigator, "vibrate", {
      value: vibrate,
      configurable: true,
    });

    const { hapticTick } = await import("./Haptics");
    hapticTick();

    expect(vibrate).toHaveBeenCalledWith(10);
    expect(document.querySelector("input[switch]")).toBeNull();
  });

  it("toggles a hidden switch where it cannot, which iOS answers with a tick", async () => {
    const { hapticTick } = await import("./Haptics");

    hapticTick();
    hapticTick();

    const inputs = document.querySelectorAll<HTMLInputElement>("input[switch]");

    expect(inputs).toHaveLength(1);
    expect(inputs[0].closest("label")?.style.display).toBe("none");
  });
});

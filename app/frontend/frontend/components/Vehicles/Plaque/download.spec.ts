import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { capturePlaque } from "./download";

const { toPng } = vi.hoisted(() => ({
  toPng: vi.fn<(node: HTMLElement) => Promise<string>>(),
}));

vi.mock("dom-to-image", () => ({ default: { toPng } }));

describe("capturePlaque", () => {
  let element: HTMLElement;

  beforeEach(() => {
    element = document.createElement("div");
    document.body.append(element);

    vi.stubGlobal(
      "fetch",
      vi.fn(async () => new Response(new Blob(["font"]))),
    );
  });

  afterEach(() => {
    element.remove();
    vi.unstubAllGlobals();
    toPng.mockReset();
  });

  it("carries the plaque's fonts into the picture", async () => {
    let fonts = "";
    toPng.mockImplementation(async (node) => {
      fonts = node.querySelector("style")?.textContent ?? "";
      return "data:image/png;base64,";
    });

    await capturePlaque(element);

    expect(fonts).toContain('font-family:"Orbitron"');
    expect(fonts).toContain('font-family:"Open Sans"');
    expect(fonts).toContain("src:url(data:");
  });

  it("leaves the plaque on screen as it was", async () => {
    toPng.mockRejectedValue(new Error("failed"));

    await expect(capturePlaque(element)).rejects.toThrow("failed");

    expect(element.querySelector("style")).toBeNull();
  });
});

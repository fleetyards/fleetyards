import { afterEach, describe, expect, it, vi } from "vitest";
import { downloadImage } from "./PhotoSwipe";

describe("downloadImage", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it("saves an image served from a path on this host", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => new Response(new Blob(["image"]), { status: 200 })),
    );
    URL.createObjectURL = vi.fn(() => "blob:local");
    URL.revokeObjectURL = vi.fn();
    const open = vi.spyOn(window, "open").mockImplementation(() => null);
    const click = vi
      .spyOn(HTMLAnchorElement.prototype, "click")
      .mockImplementation(function (this: HTMLAnchorElement) {
        expect(this.download).toBe("Poster.png");
      });

    await downloadImage("/rails/active_storage/blobs/poster.png", "Poster");

    expect(click).toHaveBeenCalled();
    expect(open).not.toHaveBeenCalled();
  });
});

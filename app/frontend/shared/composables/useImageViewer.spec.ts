import { afterEach, describe, expect, it, vi } from "vitest";
import { useImageViewer } from "./useImageViewer";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

type Registered = { onClick: () => void };

const registered: Registered[] = [];

vi.mock("photoswipe", () => ({
  default: vi.fn(function PhotoSwipe(this: Record<string, unknown>) {
    const handlers: Record<string, () => void> = {};
    this.currSlide = { data: { src: "https://media.test/paint/source.jpg" } };
    this.ui = {
      registerElement: (element: Registered) => registered.push(element),
    };
    this.on = (event: string, handler: () => void) => {
      handlers[event] = handler;
    };
    this.init = () => handlers.uiRegister?.();
  }),
}));

const image = () => {
  const element = document.createElement("img");
  Object.defineProperty(element, "naturalWidth", { value: 1920 });
  Object.defineProperty(element, "naturalHeight", { value: 1080 });
  element.src = "https://media.test/paint/source.jpg";
  return element;
};

describe("useImageViewer", () => {
  afterEach(() => {
    registered.length = 0;
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it("saves the image under the item's name", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => new Response(new Blob(["image"]), { status: 200 })),
    );
    URL.createObjectURL = vi.fn(() => "blob:paint");
    URL.revokeObjectURL = vi.fn();
    const click = vi
      .spyOn(HTMLAnchorElement.prototype, "click")
      .mockImplementation(function (this: HTMLAnchorElement) {
        expect(this.download).toBe("Cutlass - Akuma Paint.jpg");
        expect(this.href).toBe("blob:paint");
      });

    const { openImage } = useImageViewer();
    await openImage(image(), "Cutlass - Akuma Paint");

    registered[0].onClick();
    await vi.waitFor(() => expect(click).toHaveBeenCalled());
  });

  it("opens the image in a tab of its own when its host refuses the fetch", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => {
        throw new TypeError("Failed to fetch");
      }),
    );
    const open = vi.spyOn(window, "open").mockImplementation(() => null);

    const { openImage } = useImageViewer();
    await openImage(image(), "Cutlass - Akuma Paint");

    registered[0].onClick();
    await vi.waitFor(() =>
      expect(open).toHaveBeenCalledWith(
        "https://media.test/paint/source.jpg",
        "_blank",
        "noopener",
      ),
    );
  });
});

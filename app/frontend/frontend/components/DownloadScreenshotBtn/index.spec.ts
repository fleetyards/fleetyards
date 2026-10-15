import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";

const html2canvas = vi.fn();

vi.mock("html2canvas", () => ({
  default: (...args: unknown[]) => html2canvas(...args),
}));

const downloadJs = vi.fn();

vi.mock("downloadjs", () => ({
  default: (...args: unknown[]) => downloadJs(...args),
}));

const displayAlert = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess: vi.fn(), displayAlert }),
}));

const reportError = vi.fn();

vi.mock("@/shared/plugins/Appsignal", () => ({
  reportError: (...args: unknown[]) => reportError(...args),
}));

const canvas = (blob: Blob | null) =>
  ({
    width: 100,
    height: 100,
    toBlob: (callback: (value: Blob | null) => void) => callback(blob),
  }) as unknown as HTMLCanvasElement;

const chart = (width: number, height: number) => {
  const parent = document.createElement("div");
  const element = document.createElement("div");
  element.id = "fleetchart";
  element.getBoundingClientRect = () =>
    ({
      width,
      height,
      top: 0,
      left: 0,
      right: width,
      bottom: height,
    }) as DOMRect;
  parent.appendChild(element);
  document.body.appendChild(parent);

  return element;
};

const mounted: { unmount: () => void }[] = [];

const clickDownload = async () => {
  const wrapper = await mountWithDefaults(Component, {
    props: { element: "#fleetchart", filename: "fleet" },
  });
  mounted.push(wrapper);

  await wrapper.find("button").trigger("click");
  await flushPromises();

  return wrapper;
};

describe("DownloadScreenshotBtn", () => {
  beforeEach(() => {
    vi.stubGlobal("devicePixelRatio", 2);
  });

  afterEach(() => {
    mounted.splice(0).forEach((wrapper) => wrapper.unmount());
    document.body.innerHTML = "";
    vi.unstubAllGlobals();
    vi.clearAllMocks();
  });

  it("downloads the chart at the screen's pixel ratio", async () => {
    chart(1000, 500);
    const png = new Blob(["png"], { type: "image/png" });
    html2canvas.mockResolvedValue(canvas(png));

    await clickDownload();

    expect(html2canvas.mock.calls[0][1].scale).toBe(2);
    expect(downloadJs).toHaveBeenCalledWith(png, "fleetyards-fleet.png");
    expect(displayAlert).not.toHaveBeenCalled();
  });

  it("scales a large chart down to fit the canvas limit", async () => {
    chart(1740, 25000);
    html2canvas.mockResolvedValue(canvas(new Blob(["png"])));

    await clickDownload();

    const { scale } = html2canvas.mock.calls[0][1];
    expect(scale).toBeLessThan(1);
    expect(1740 * scale * 25000 * scale).toBeLessThanOrEqual(16_777_216);
    expect(25000 * scale).toBeLessThanOrEqual(16_384);
  });

  it("keeps the pixel ratio for a large chart zoomed out to fit", async () => {
    // A 1740x25000 chart shown at a quarter of its size.
    chart(435, 6250);
    html2canvas.mockResolvedValue(canvas(new Blob(["png"])));

    await clickDownload();

    expect(html2canvas.mock.calls[0][1].scale).toBe(2);
  });

  it("tells the user and reports it when the chart cannot be drawn", async () => {
    const element = chart(1000, 500);
    const error = new Error("boom");
    html2canvas.mockRejectedValue(error);

    const wrapper = await clickDownload();

    expect(downloadJs).not.toHaveBeenCalled();
    expect(displayAlert).toHaveBeenCalledOnce();
    expect(reportError).toHaveBeenCalledWith(
      error,
      "DownloadScreenshotBtn#download",
    );
    expect(element.classList.contains("fleetchart-download")).toBe(false);
    expect(wrapper.find("button").attributes("disabled")).toBeUndefined();
  });

  it("tells the user when the canvas comes back empty", async () => {
    chart(1000, 500);
    html2canvas.mockResolvedValue(canvas(null));

    await clickDownload();

    expect(downloadJs).not.toHaveBeenCalled();
    expect(displayAlert).toHaveBeenCalledOnce();
    expect(reportError).toHaveBeenCalledOnce();
  });
});

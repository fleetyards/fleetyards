import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { afterEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import {
  plaqueFile,
  savePlaque,
  sharePlaque,
} from "@/frontend/components/Vehicles/Plaque/download";

vi.mock("@/frontend/components/Vehicles/Plaque/download", () => ({
  plaqueFile: vi.fn(),
  savePlaque: vi.fn(),
  sharePlaque: vi.fn(),
}));

const file = new File(["png"], "fleetyards-plaque.png", { type: "image/png" });

const mount = async () => {
  document.body.innerHTML = '<div id="plaque"></div>';

  return mountWithDefaults<typeof Component>(Component, {
    props: { element: "plaque", filename: "plaque" },
  });
};

describe("VehiclePlaqueDownloadBtn", () => {
  afterEach(() => {
    vi.mocked(plaqueFile).mockReset();
    vi.mocked(savePlaque).mockReset();
    vi.mocked(sharePlaque).mockReset();
  });

  it("draws the plaque and saves it", async () => {
    vi.mocked(plaqueFile).mockResolvedValue(file);
    const wrapper = await mount();

    await wrapper.find("button").trigger("click");
    await flushPromises();

    expect(savePlaque).toHaveBeenCalledWith(file);
    expect(wrapper.text()).toContain("Save as PNG");
  });

  it("keeps the picture for the next tap when the share sheet is refused", async () => {
    vi.mocked(plaqueFile).mockResolvedValue(file);
    vi.mocked(savePlaque)
      .mockRejectedValueOnce(new DOMException("late", "NotAllowedError"))
      .mockResolvedValueOnce(undefined);
    const wrapper = await mount();

    await wrapper.find("button").trigger("click");
    await flushPromises();

    expect(wrapper.text()).toContain("Share");

    await wrapper.find("button").trigger("click");
    await flushPromises();

    expect(plaqueFile).toHaveBeenCalledTimes(1);
    expect(savePlaque).toHaveBeenNthCalledWith(2, file);
    expect(wrapper.text()).toContain("Save as PNG");
  });

  it("drops the kept picture when the plaque changes", async () => {
    vi.mocked(plaqueFile).mockResolvedValue(file);
    vi.mocked(savePlaque).mockRejectedValueOnce(
      new DOMException("late", "NotAllowedError"),
    );
    const wrapper = await mount();

    await wrapper.find("button").trigger("click");
    await flushPromises();
    expect(wrapper.text()).toContain("Share");

    document.getElementById("plaque")!.textContent = "Renamed";
    await flushPromises();

    expect(wrapper.text()).toContain("Save as PNG");

    await wrapper.find("button").trigger("click");
    await flushPromises();

    expect(plaqueFile).toHaveBeenCalledTimes(2);
  });

  it("gives up after the share sheet is refused twice", async () => {
    vi.mocked(plaqueFile).mockResolvedValue(file);
    vi.mocked(savePlaque).mockRejectedValue(
      new DOMException("blocked", "NotAllowedError"),
    );
    const wrapper = await mount();

    await wrapper.find("button").trigger("click");
    await flushPromises();
    await wrapper.find("button").trigger("click");
    await flushPromises();

    expect(savePlaque).toHaveBeenCalledTimes(2);
    expect(wrapper.text()).toContain("Save as PNG");
  });

  it("says nothing when the share sheet is dismissed", async () => {
    vi.mocked(plaqueFile).mockResolvedValue(file);
    vi.mocked(savePlaque).mockRejectedValue(
      new DOMException("dismissed", "AbortError"),
    );
    const wrapper = await mount();

    await wrapper.find("button").trigger("click");
    await flushPromises();

    expect(wrapper.text()).toContain("Save as PNG");
  });

  it("hands the picture to the share sheet in share mode", async () => {
    vi.mocked(plaqueFile).mockResolvedValue(file);
    document.body.innerHTML = '<div id="plaque"></div>';
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        element: "plaque",
        filename: "plaque",
        share: true,
        shareTitle: "Corsair",
      },
    });

    expect(wrapper.text()).toContain("Share");

    await wrapper.find("button").trigger("click");
    await flushPromises();

    expect(sharePlaque).toHaveBeenCalledWith(file, "Corsair");
    expect(savePlaque).not.toHaveBeenCalled();
  });
});

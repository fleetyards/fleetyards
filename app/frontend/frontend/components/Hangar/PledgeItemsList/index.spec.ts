import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPledgeItemKindEnum,
  type HangarPledgeItem,
} from "@/services/fyApi";
import Component from "./index.vue";

const pledgeItem = (
  attrs: Partial<HangarPledgeItem> = {},
): HangarPledgeItem => ({
  id: "0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c",
  rsiPledgeId: "00064530",
  kind: HangarPledgeItemKindEnum.PAINT,
  name: "Cutlass - Akuma Paint",
  quantity: 1,
  standalone: true,
  meltable: false,
  createdAt: "2026-10-08T12:00:00Z",
  updatedAt: "2026-10-08T12:00:00Z",
  ...attrs,
});

const mount = async (items: HangarPledgeItem[]) =>
  mountWithDefaults(Component, {
    props: { items, icon: "fa-duotone fa-paintbrush" },
  });

describe("Hangar/PledgeItemsList", () => {
  it("names the item and the pledge it came in", async () => {
    const wrapper = await mount([pledgeItem()]);

    expect(wrapper.text()).toContain("Cutlass - Akuma Paint");
    expect(wrapper.text()).toContain("Pledge 00064530");
  });

  it("counts an item only when the pledge holds more than one", async () => {
    const wrapper = await mount([
      pledgeItem(),
      pledgeItem({
        id: "1f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c",
        kind: HangarPledgeItemKindEnum.FLAIR,
        name: "Poster - Banu Merchantman",
        quantity: 2,
      }),
    ]);

    const rows = wrapper.findAll("[data-test='pledge-item-row']");
    expect(rows[0].text()).not.toContain("×");
    expect(rows[1].text()).toContain("× 2");
  });

  it("shows the item's image, or the list's icon without one", async () => {
    const wrapper = await mount([
      pledgeItem({ image: "https://media.test/akuma.jpg" }),
      pledgeItem({ id: "2f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c" }),
    ]);

    const rows = wrapper.findAll("[data-test='pledge-item-row']");
    expect(rows[0].find("img").attributes("src")).toBe(
      "https://media.test/akuma.jpg",
    );
    expect(rows[1].find(".fa-paintbrush").exists()).toBe(true);
  });

  it("shows the melt value of an item that is its whole pledge", async () => {
    const wrapper = await mount([pledgeItem({ meltValue: 9, pledgeValue: 9 })]);

    expect(wrapper.text()).toContain("Melt value");
    expect(wrapper.text()).toContain("$9.00");
  });

  it("names the pledge an item came in with others, and that pledge's value", async () => {
    const wrapper = await mount([
      pledgeItem({
        name: "CSV - Granite Paint",
        standalone: false,
        pledgeName: "Standalone Ships - CSV-SM plus Granite Paint",
        pledgeValue: 40,
      }),
    ]);

    expect(wrapper.text()).toContain(
      "Part of Standalone Ships - CSV-SM plus Granite Paint",
    );
    expect(wrapper.text()).toContain("Pledge value");
    expect(wrapper.text()).not.toContain("Melt value");
  });

  it("marks what RSI offers to melt, and says when the pledge was created", async () => {
    const wrapper = await mount([
      pledgeItem({ meltable: true, pledgeCreatedOn: "2026-10-08" }),
      pledgeItem({ id: "3f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c" }),
    ]);

    const rows = wrapper.findAll("[data-test='pledge-item-row']");
    expect(rows[0].text()).toContain("Meltable");
    expect(rows[0].text()).toContain("8 Oct 2026");
    expect(rows[1].text()).not.toContain("Meltable");
  });

  it("opens the image full size on click", async () => {
    const init = vi.fn();
    const on = vi.fn();
    const PhotoSwipe = vi.fn(function PhotoSwipe(this: {
      init: () => void;
      on: () => void;
    }) {
      this.init = init;
      this.on = on;
    });
    vi.doMock("photoswipe", () => ({ default: PhotoSwipe }));

    const wrapper = await mount([
      pledgeItem({ image: "https://media.test/akuma.jpg" }),
    ]);

    const image = wrapper.find("img").element as HTMLImageElement;
    Object.defineProperty(image, "naturalWidth", { value: 1920 });
    Object.defineProperty(image, "naturalHeight", { value: 1080 });

    await wrapper.find("[data-test='pledge-item-image']").trigger("click");
    await vi.waitFor(() => expect(init).toHaveBeenCalled());

    expect(PhotoSwipe).toHaveBeenCalledWith(
      expect.objectContaining({
        dataSource: [
          expect.objectContaining({
            src: "https://media.test/akuma.jpg",
            width: 1920,
            height: 1080,
            alt: "Cutlass - Akuma Paint",
          }),
        ],
      }),
    );
    expect(on).toHaveBeenCalledWith("uiRegister", expect.any(Function));
  });
});

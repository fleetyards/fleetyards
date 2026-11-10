import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { OutfitSlotEnum } from "@/services/fyApi";

const { default: Loadout } = await import("./index.vue");

const row = (slot: OutfitSlotEnum) => ({
  slot,
  label: slot,
  selected: slot === OutfitSlotEnum.MAGAZINE_1,
});

const mount = (props: Record<string, unknown> = {}) =>
  mountWithDefaults<typeof Loadout>(Loadout, {
    props: {
      tabs: [
        { key: "armour", slots: [OutfitSlotEnum.HELMET] },
        { key: "weapons", slots: [OutfitSlotEnum.PRIMARY] },
      ],
      supplies: [
        {
          key: "magazine",
          slots: [OutfitSlotEnum.MAGAZINE_1, OutfitSlotEnum.MAGAZINE_2],
        },
      ],
      row,
      ...props,
    } as never,
  });

const visible = (wrapper: Awaited<ReturnType<typeof mount>>, test: string) =>
  wrapper
    .find(`[data-test="${test}"]`)
    .element.closest("[role=tabpanel]") as HTMLElement | null;

describe("DressingRoomLoadout", () => {
  it("opens on the first tab and switches to another", async () => {
    const wrapper = await mount();

    expect(visible(wrapper, "dressing-room-slots-armour")?.style.display).toBe(
      "",
    );
    expect(visible(wrapper, "dressing-room-slots-weapons")?.style.display).toBe(
      "none",
    );

    await wrapper
      .find('[data-test="dressing-room-tab-weapons"]')
      .trigger("click");

    expect(visible(wrapper, "dressing-room-slots-armour")?.style.display).toBe(
      "none",
    );
    expect(visible(wrapper, "dressing-room-slots-weapons")?.style.display).toBe(
      "",
    );
  });

  it("falls back to the first tab when the one open goes", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="dressing-room-tab-weapons"]')
      .trigger("click");
    await wrapper.setProps({
      tabs: [{ key: "armour", slots: [OutfitSlotEnum.HELMET] }],
    } as never);

    expect(
      wrapper
        .find('[data-test="dressing-room-tab-armour"]')
        .attributes("aria-selected"),
    ).toBe("true");
    expect(visible(wrapper, "dressing-room-slots-armour")?.style.display).toBe(
      "",
    );
  });

  it("moves along the tabs with the arrow keys", async () => {
    const wrapper = await mount();
    const tabs = wrapper.find('[role="tablist"]');

    await tabs.trigger("keydown", { key: "ArrowRight" });
    expect(
      wrapper
        .find('[data-test="dressing-room-tab-weapons"]')
        .attributes("aria-selected"),
    ).toBe("true");

    await tabs.trigger("keydown", { key: "ArrowLeft" });
    await tabs.trigger("keydown", { key: "ArrowLeft" });
    expect(
      wrapper
        .find('[data-test="dressing-room-tab-supplies"]')
        .attributes("aria-selected"),
    ).toBe("true");
  });

  it("ties each tab to its panel", async () => {
    const wrapper = await mount();
    const tab = wrapper.find('[data-test="dressing-room-tab-weapons"]');
    const panel = wrapper.find(`#${tab.attributes("aria-controls")}`);

    expect(panel.attributes("aria-labelledby")).toBe(tab.attributes("id"));
  });

  it("leaves the supplies tab out with nothing to hold and nothing to say", async () => {
    const wrapper = await mount({ supplies: [] });

    expect(
      wrapper.find('[data-test="dressing-room-tab-supplies"]').exists(),
    ).toBe(false);
  });

  it("counts the supplies filled of each kind", async () => {
    const wrapper = await mount();

    expect(
      wrapper.find('[data-test="dressing-room-gear-columns"]').text(),
    ).toContain("1 of 2");
  });

  it("says what to wear while nothing carries supplies", async () => {
    const wrapper = await mount({ supplies: [], suppliesHint: "Wear a core" });

    expect(wrapper.find('[data-test="dressing-room-gear-hint"]').text()).toBe(
      "Wear a core",
    );
  });

  it("hands a picked slot up", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="dressing-room-pick-magazine_2"]')
      .trigger("click");

    expect(wrapper.emitted("pick")).toEqual([[OutfitSlotEnum.MAGAZINE_2]]);
  });

  it("hands every slot of a kind up to fill at once", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="dressing-room-fill-magazine"]')
      .trigger("click");

    expect(wrapper.emitted("fill")).toEqual([
      [[OutfitSlotEnum.MAGAZINE_1, OutfitSlotEnum.MAGAZINE_2]],
    ]);
  });
});

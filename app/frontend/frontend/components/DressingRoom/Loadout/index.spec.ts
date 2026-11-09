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
});

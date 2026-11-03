import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { type ArmorSet, OutfitSlotEnum } from "@/services/fyApi";

const set = (name: string, slug = name): ArmorSet => ({
  name,
  manufacturerName: "Clark Defense Systems",
  itemType: "heavy_armor",
  itemTypeLabel: "Heavy Armor",
  image: null,
  pieces: [{ slot: OutfitSlotEnum.TORSO, slug, name: `${name} Core` }],
});

const sets = ref<ArmorSet[]>([]);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useArmorSets: () => ({ data: sets, isLoading: ref(false) }),
}));

const { default: ArmorSetsModal } = await import("./index.vue");

const mount = () =>
  mountWithDefaults<typeof ArmorSetsModal>(ArmorSetsModal, {
    props: { selection: { [OutfitSlotEnum.TORSO]: "adp" } },
  });

const card = (slug: string) => `[data-test="dressing-room-armor-set-${slug}"]`;

describe("DressingRoomArmorSetsModal", () => {
  it("marks the worn set and hands over the one picked", async () => {
    sets.value = [set("adp"), set("orc")];

    const wrapper = await mount();

    expect(wrapper.find(card("adp")).classes()).toContain(
      "picker-card--selected",
    );
    expect(wrapper.find(card("orc")).classes()).not.toContain(
      "picker-card--selected",
    );

    await wrapper.find(`${card("orc")} button`).trigger("click");

    expect(wrapper.emitted("select")?.[0]?.[0]).toMatchObject({ name: "orc" });
  });

  it("shows a page at a time, and searches the whole list", async () => {
    sets.value = Array.from({ length: 50 }, (_, index) => set(`set-${index}`));

    const wrapper = await mount();
    const more = '[data-test="dressing-room-armor-sets-more"]';

    expect(wrapper.findAll(".picker-card")).toHaveLength(48);

    await wrapper
      .find('input[name="catalogue-picker-search"]')
      .setValue("set-49");
    await flushPromises();

    expect(wrapper.find(card("set-49")).exists()).toBe(true);
    expect(wrapper.find(more).exists()).toBe(false);
  });
});

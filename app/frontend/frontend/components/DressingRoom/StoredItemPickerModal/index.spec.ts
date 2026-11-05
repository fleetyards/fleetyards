import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";

const ITEMS = [
  {
    id: "pen",
    name: "MedPen",
    slug: "medpen",
    media: {},
    volume: 0.00018,
    volumeDimensions: { x: 0.03, y: 0.03, z: 0.1 },
  },
  {
    id: "railgun",
    name: "Railgun",
    slug: "railgun",
    media: {},
    volume: 0.05,
    volumeDimensions: { x: 1.8, y: 0.2, z: 0.2 },
  },
  { id: "prop", name: "Prop", slug: "prop", media: {}, volume: null },
];

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  equipment: () =>
    Promise.resolve({
      items: ITEMS,
      meta: { pagination: { currentPage: 1, totalPages: 1 } },
    }),
  equipmentTypesFilters: () => Promise.resolve([]),
}));

const { default: Picker } = await import("./index.vue");

const mount = async (used = 0) => {
  const wrapper = await mountWithDefaults<typeof Picker>(Picker, {
    props: {
      holder: "backpack",
      inventory: { capacity: 150_000, dimensions: { x: 0.64, y: 1, z: 0.45 } },
      used: () => used,
    },
  });
  await flushPromises();

  return wrapper;
};

const card = (wrapper: Awaited<ReturnType<typeof mount>>, slug: string) =>
  wrapper.find(`[data-test="dressing-room-stored-option-${slug}"]`);

describe("DressingRoomStoredItemPickerModal", () => {
  it("picks an item that fits", async () => {
    const wrapper = await mount();

    expect(card(wrapper, "medpen").classes()).not.toContain(
      "picker-card--disabled",
    );

    await card(wrapper, "medpen").find("button").trigger("click");

    expect(wrapper.emitted("select")?.[0]?.[0]).toMatchObject({
      slug: "medpen",
    });
  });

  it("greys out what is too large or was never measured, with the reason", async () => {
    const wrapper = await mount();

    expect(card(wrapper, "railgun").classes()).toContain(
      "picker-card--disabled",
    );
    expect(card(wrapper, "railgun").text()).toContain(
      "Too large for this piece",
    );
    expect(card(wrapper, "prop").text()).toContain("No measured size");
  });

  it("greys out what no longer has room", async () => {
    const wrapper = await mount(149_900);

    expect(card(wrapper, "medpen").text()).toContain("Not enough room left");
  });
});

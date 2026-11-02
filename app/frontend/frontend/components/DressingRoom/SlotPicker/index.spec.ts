import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";

const fetchEquipment = vi.fn((_params: unknown) =>
  Promise.resolve({
    items: [{ id: "core", name: "ADP Core", slug: "adp-core", media: {} }],
    meta: { pagination: { currentPage: 1, totalPages: 1 } },
  }),
);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  equipment: (params: unknown) => fetchEquipment(params),
}));

const { default: SlotPicker } = await import("./index.vue");

describe("DressingRoomSlotPicker", () => {
  it("offers only armour and undersuits that fit the slot", async () => {
    const wrapper = await mountWithDefaults<typeof SlotPicker>(SlotPicker, {
      props: { slot: "torso" },
    });
    await flushPromises();

    expect(fetchEquipment).toHaveBeenCalledWith(
      expect.objectContaining({
        q: expect.objectContaining({
          slotIn: ["torso"],
          equipmentTypeIn: ["armor", "undersuit"],
        }),
      }),
    );

    await wrapper
      .find('[data-test="dressing-room-option-adp-core"]')
      .trigger("click");

    expect(wrapper.emitted("select")?.[0]?.[0]).toMatchObject({
      slug: "adp-core",
    });
  });
});

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

const closed = vi.fn();

vi.mock("@/shared/composables/useComlink", async (importOriginal) => {
  const actual =
    await importOriginal<typeof import("@/shared/composables/useComlink")>();

  return {
    ...actual,
    useComlink: () => {
      const comlink = actual.useComlink();

      return {
        ...comlink,
        emit: (event: string, ...args: unknown[]) => {
          if (event === "close-modal") closed();

          return (comlink.emit as (...params: unknown[]) => unknown)(
            event,
            ...args,
          );
        },
      };
    },
  };
});

const { default: SlotPicker } = await import("./index.vue");

describe("DressingRoomSlotPickerModal", () => {
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
      .find('[data-test="dressing-room-option-adp-core"] button')
      .trigger("click");

    expect(wrapper.emitted("select")?.[0]?.[0]).toMatchObject({
      slug: "adp-core",
    });
    expect(closed).toHaveBeenCalled();
  });

  it("greys out what the worn pieces leave no room for, and says why", async () => {
    closed.mockClear();
    fetchEquipment.mockResolvedValueOnce({
      items: [
        {
          id: "heavy",
          name: "Heavy Pack",
          slug: "heavy-pack",
          media: {},
          size: "3",
          fit: { type: "Char_Armor_Backpack" },
        },
      ],
      meta: { pagination: { currentPage: 1, totalPages: 1 } },
    } as never);

    const wrapper = await mountWithDefaults<typeof SlotPicker>(SlotPicker, {
      props: {
        slot: "backpack",
        fit: {
          kind: "ports",
          ports: [
            {
              name: "backpack",
              types: [{ type: "Char_Armor_Backpack" }],
              minSize: 1,
              maxSize: 1,
            },
          ],
          providers: [{ name: "Light Core" }],
        },
      },
    });
    await flushPromises();

    const card = wrapper.find('[data-test="dressing-room-option-heavy-pack"]');
    expect(card.classes()).toContain("picker-card--disabled");
    expect(card.text()).toContain("Light Core");

    await card.find("button").trigger("click");

    expect(wrapper.emitted("select")).toBeUndefined();
    expect(closed).not.toHaveBeenCalled();
  });

  it("shows a weapon's size beside its maker and type", async () => {
    fetchEquipment.mockResolvedValueOnce({
      items: [
        {
          id: "p4",
          name: "P4-AR Rifle",
          slug: "p4-ar-rifle",
          media: {},
          equipmentType: "weapon",
          itemTypeLabel: "Assault Rifle",
          size: "2",
          manufacturer: { name: "Behring" },
        },
      ],
      meta: { pagination: { currentPage: 1, totalPages: 1 } },
    } as never);

    const weapons = await mountWithDefaults<typeof SlotPicker>(SlotPicker, {
      props: { slot: "primary" },
    });
    await flushPromises();

    const option = weapons.find(
      '[data-test="dressing-room-option-p4-ar-rifle"]',
    );
    expect(option.text()).toContain("Behring · Assault Rifle");
    expect(option.find('[data-test="dressing-room-item-size"]').text()).toBe(
      "S2",
    );
  });

  it("shows armour's weight and figures, but no size", async () => {
    fetchEquipment.mockResolvedValueOnce({
      items: [
        {
          id: "antium",
          name: "Antium Helmet",
          slug: "antium-helmet",
          media: {},
          equipmentType: "armor",
          itemTypeLabel: "Heavy Armor",
          size: "1",
          damageReduction: 40,
        },
      ],
      meta: { pagination: { currentPage: 1, totalPages: 1 } },
    } as never);

    const armour = await mountWithDefaults<typeof SlotPicker>(SlotPicker, {
      props: { slot: "helmet" },
    });
    await flushPromises();

    const helmet = armour.find(
      '[data-test="dressing-room-option-antium-helmet"]',
    );
    expect(helmet.text()).toContain("Heavy Armor");
    expect(helmet.find('[data-test="dressing-room-item-size"]').exists()).toBe(
      false,
    );
    expect(helmet.find('[data-test="dressing-room-item-stats"]').exists()).toBe(
      true,
    );
  });
});

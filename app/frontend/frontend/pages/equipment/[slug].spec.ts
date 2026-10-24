import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import { EquipmentTypeEnum, type Equipment } from "@/services/fyApi";

const item = vi.hoisted(() => ({ value: undefined as unknown }));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useEquipmentItem: () => ({ data: ref(item.value) }),
  useBlueprints: () => ({ data: ref({ items: [] }), isPending: ref(false) }),
  useBlueprint: () => ({
    data: ref(undefined),
    isPlaceholderData: ref(false),
  }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    tExists: () => false,
    toNumber: (value: number) => String(value),
  }),
}));

vi.mock("@/shared/composables/useMetaInfo", () => ({
  useMetaInfo: () => ({ updateMetaInfo: vi.fn() }),
}));

import EquipmentPage from "./[slug].vue";

const record = (overrides: Partial<Equipment> = {}): Equipment =>
  ({
    id: "e0000000-0000-0000-0000-000000000001",
    name: "P4-AR Rifle",
    slug: "p4-ar-rifle",
    equipmentType: EquipmentTypeEnum.WEAPON,
    equipmentTypeLabel: "Weapon",
    retired: false,
    availability: { boughtAt: [], soldAt: [] },
    createdAt: "2026-09-01T00:00:00Z",
    updatedAt: "2026-09-02T00:00:00Z",
    ...overrides,
  }) as Equipment;

const mountPage = async (equipment: Equipment) => {
  item.value = equipment;

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: "/equipment/:slug/",
        name: "equipment-item",
        component: { template: "<div />" },
      },
      { path: "/equipment/", name: "equipment", component: { template: "<div />" } },
    ],
  });
  await router.push(`/equipment/${equipment.slug}/`);
  await router.isReady();

  return mount(EquipmentPage, {
    global: {
      plugins: [router],
      stubs: {
        AsyncData: { template: "<div><slot name='resolved' /></div>" },
        BreadCrumbs: true,
        ExternalLinks: true,
        Availability: true,
        Chip: true,
        EquipmentStatsCard: true,
        CatalogueItemPopover: true,
        MetricsCard: { template: "<section><slot /></section>" },
      },
    },
  });
};

describe("EquipmentPage", () => {
  it("shows the store image when there is one", async () => {
    const wrapper = await mountPage(
      record({
        storeImage: { largeUrl: "https://example.test/large.jpg" },
      } as Partial<Equipment>),
    );

    expect(
      wrapper.find("[data-test='equipment-image'] img").attributes("src"),
    ).toBe("https://example.test/large.jpg");
  });

  it("leaves the image out without a store image", async () => {
    const wrapper = await mountPage(record());

    expect(wrapper.find("[data-test='equipment-image']").exists()).toBe(false);
  });
});

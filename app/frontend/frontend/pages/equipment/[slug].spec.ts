import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import {
  EquipmentTypeEnum,
  type Equipment,
  type EquipmentAttachment,
} from "@/services/fyApi";

const item = vi.hoisted(() => ({ value: undefined as unknown }));
const related = vi.hoisted(() => ({
  versions: [] as unknown[],
  attachments: [] as unknown[],
  weapons: [] as unknown[],
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useEquipmentItem: () => ({ data: ref(item.value) }),
  useEquipmentItemVersions: () => ({ data: ref(related.versions) }),
  useEquipmentItemAttachments: () => ({ data: ref(related.attachments) }),
  useEquipmentItemWeapons: () => ({ data: ref(related.weapons) }),
  useBlueprints: () => ({ data: ref({ items: [] }), isPending: ref(false) }),
  useBlueprint: () => ({
    data: ref(undefined),
    isPlaceholderData: ref(false),
  }),
}));

vi.mock("@/shared/composables/useMobile", () => ({
  useMobile: () => ref(false),
}));

vi.mock("@/shared/composables/useLowPowerDevice", () => ({
  useLowPowerDevice: () => ref(false),
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

const mountPage = async (
  equipment: Equipment,
  {
    versions = [],
    attachments = [],
    weapons = [],
  }: {
    versions?: Equipment[];
    attachments?: EquipmentAttachment[];
    weapons?: Equipment[];
  } = {},
) => {
  item.value = equipment;
  Object.assign(related, { versions, attachments, weapons });

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: "/equipment/:slug/",
        name: "equipment-item",
        component: { template: "<div />" },
      },
      {
        path: "/equipment/",
        name: "equipment",
        component: { template: "<div />" },
      },
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
        ItemViews: true,
        CatalogueItemPopover: true,
        MetricsCard: {
          props: ["title"],
          template: "<section><h3>{{ title }}</h3><slot /></section>",
        },
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
      wrapper.find("[data-test='equipment-image']").attributes("src"),
    ).toBe("https://example.test/large.jpg");
  });

  it("lists the item's other versions", async () => {
    const wrapper = await mountPage(record(), {
      versions: [
        record({ id: "e2", name: 'P4-AR "Boneyard" Rifle', slug: "boneyard" }),
      ],
    });

    expect(
      wrapper.find("[data-test='equipment-versions'] a").attributes("href"),
    ).toBe("/equipment/boneyard/");
  });

  it("groups a weapon's attachments by port and marks what it ships with", async () => {
    const fit = (portType: string, name: string, isDefault = false) =>
      ({
        portType,
        default: isDefault,
        attachment: record({
          id: name,
          name,
          slug: name.toLowerCase(),
          equipmentType: EquipmentTypeEnum.WEAPON_ATTACHMENT,
        }),
      }) as EquipmentAttachment;

    const wrapper = await mountPage(record(), {
      attachments: [
        fit("Magazine", "Mag", true),
        fit("IronSight", "Delta"),
        fit("IronSight", "Gamma"),
        fit("SomethingNew", "Odd"),
      ],
    });

    const cards = wrapper.findAll(
      "[data-test='equipment-attachments'] section",
    );

    expect(cards.map((card) => card.find("h3").text())).toEqual([
      "labels.equipment.ports.Magazine",
      "labels.equipment.ports.IronSight",
      "labels.equipment.ports.other",
    ]);
    expect(cards[0].text()).toContain("labels.equipment.standard");
    expect(cards[1].findAll("a")).toHaveLength(2);
    expect(cards[1].text()).not.toContain("labels.equipment.standard");
  });

  it("lists the weapons an attachment fits rather than ports", async () => {
    const wrapper = await mountPage(
      record({ equipmentType: EquipmentTypeEnum.WEAPON_ATTACHMENT }),
      {
        attachments: [
          {
            portType: "Magazine",
            default: false,
            attachment: record(),
          } as EquipmentAttachment,
        ],
        weapons: [record({ id: "w1", name: "Gallant Rifle", slug: "gallant" })],
      },
    );

    expect(wrapper.find("[data-test='equipment-attachments']").exists()).toBe(
      false,
    );
    expect(
      wrapper.find("[data-test='equipment-weapons'] a").attributes("href"),
    ).toBe("/equipment/gallant/");
  });

  it("leaves the image out without a store image", async () => {
    const wrapper = await mountPage(record());

    expect(wrapper.find("[data-test='equipment-image']").exists()).toBe(false);
  });
});

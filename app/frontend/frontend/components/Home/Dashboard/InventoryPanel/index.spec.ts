import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { HangarInventoryItem } from "@/services/fyApi";
import Component from "./index.vue";

let entries: HangarInventoryItem[] = [];

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useHangarAllInventoryItems: () => ({
      data: computed(() => ({ items: entries })),
      isLoading: ref(false),
      isFetching: ref(false),
      isLoadingError: ref(false),
    }),
  };
});

const Stub = defineComponent({ render: () => h("div") });

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/inventories", name: "hangar-inventories", component: Stub },
      {
        path: "/inventories/:inventory/items/:item",
        name: "hangar-inventory-item",
        component: Stub,
      },
    ],
  });

  await instance.push("/");
  await instance.isReady();

  return instance;
};

const entry = (
  overrides: Partial<HangarInventoryItem> = {},
): HangarInventoryItem => ({
  id: "e1",
  name: "Quantanium",
  stockSlug: "quantanium",
  category: "commodity",
  quantity: 32,
  unit: "scu",
  entryType: "deposit",
  inventory: { name: "Lorville storage", slug: "lorville" },
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
  ...overrides,
});

const mount = async () =>
  mountWithDefaults(Component, { plugins: [await router()] });

describe("HomeDashboardInventoryPanel", () => {
  beforeEach(() => {
    entries = [];
  });

  it("stays away while the pilot keeps no inventory", async () => {
    const subject = await mount();

    expect(subject.find('[data-test="home-inventory"]').exists()).toBe(false);
  });

  it("signs what went in and what came out", async () => {
    entries = [
      entry(),
      entry({ id: "e2", entryType: "withdrawal", quantity: 4 }),
    ];

    const subject = await mount();

    const text = subject.find('[data-test="home-inventory"]').text();

    expect(text).toContain("+32");
    expect(text).toContain("−4");
    expect(text).toContain("Lorville storage");
  });
});

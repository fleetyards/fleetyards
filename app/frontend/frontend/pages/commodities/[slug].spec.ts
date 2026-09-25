import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount } from "@vue/test-utils";
import { createRouter, createMemoryHistory, type Router } from "vue-router";
import type { Commodity } from "@/services/fyApi";

const commodity = vi.hoisted(() => ({
  value: undefined as Commodity | undefined,
}));

vi.mock("@/services/fyApi", () => ({
  useCommodity: () => ({
    data: toRef(commodity, "value"),
    isLoading: ref(false),
    isFetching: ref(false),
    isError: ref(false),
  }),
  useCommodityPriceHistory: () => ({ data: ref([]) }),
  useBlueprints: () => ({ data: ref({ items: [] }), isPending: ref(false) }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    tExists: () => false,
    l: (value: string) => value,
    toNumber: (value: number) => String(value),
  }),
}));

vi.mock("@/shared/composables/useMetaInfo", () => ({
  useMetaInfo: () => ({ updateMetaInfo: vi.fn() }),
}));

import CommodityPage from "./[slug].vue";

const record = (overrides: Partial<Commodity> = {}): Commodity => ({
  id: "c0000000-0000-0000-0000-000000000001",
  name: "Construction Materials",
  slug: "construction-materials",
  commodityType: null,
  counted: false,
  consumable: false,
  containerSizes: [],
  refinesInto: null,
  refinedFrom: [],
  retired: false,
  availability: { boughtAt: [], soldAt: [] },
  createdAt: "2026-09-01T00:00:00Z",
  updatedAt: "2026-09-02T00:00:00Z",
  ...overrides,
});

const mountPage = async () => {
  const router: Router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: "/commodities/:slug/",
        name: "commodity",
        component: { template: "<div />" },
      },
      {
        path: "/commodities/",
        name: "commodities",
        component: { template: "<div />" },
      },
      {
        path: "/blueprints/:slug/",
        name: "blueprint",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({
    name: "commodity",
    params: { slug: commodity.value?.slug ?? "unknown" },
  });
  await router.isReady();

  return mount(CommodityPage, {
    global: {
      plugins: [router],
      stubs: {
        AsyncData: { template: "<div><slot name='resolved' /></div>" },
        BreadCrumbs: true,
        Chart: true,
        Availability: true,
        CommodityIcon: true,
        MetricsCard: { template: "<section><slot /></section>" },
      },
    },
  });
};

const refinementRows = (wrapper: Awaited<ReturnType<typeof mountPage>>) =>
  wrapper.findAll("a.commodity-page__link-row").map((row) => ({
    label: row.find(".metrics-card__row__label").text(),
    value: row.find(".metrics-card__row__value").text(),
    href: row.attributes("href"),
  }));

describe("CommodityPage", () => {
  beforeEach(() => {
    commodity.value = record();
  });

  it("links every raw form it is refined from, labelled once", async () => {
    commodity.value = record({
      refinedFrom: [
        { id: "c1", name: "Construction Materials (Chunks)", slug: "chunks" },
        { id: "c2", name: "Construction Materials (Powder)", slug: "powder" },
      ],
    });

    expect(refinementRows(await mountPage())).toEqual([
      {
        label: "labels.commodity.refinedFrom",
        value: "Construction Materials (Chunks)",
        href: "/commodities/chunks/",
      },
      {
        label: "",
        value: "Construction Materials (Powder)",
        href: "/commodities/powder/",
      },
    ]);
  });

  it("shows the identity card for a refinement link alone", async () => {
    commodity.value = record({
      refinesInto: { id: "c9", name: "Gold", slug: "gold" },
    });

    expect(refinementRows(await mountPage())).toEqual([
      {
        label: "labels.commodity.refinesInto",
        value: "Gold",
        href: "/commodities/gold/",
      },
    ]);
  });

  it("renders no refinement rows when there are none", async () => {
    expect(refinementRows(await mountPage())).toEqual([]);
  });
});

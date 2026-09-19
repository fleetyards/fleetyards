import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount } from "@vue/test-utils";
import { createRouter, createMemoryHistory, type Router } from "vue-router";
import { VueQueryPlugin } from "@tanstack/vue-query";
import type { Blueprint } from "@/services/fyAdminApi";

const blueprint = vi.hoisted(() => ({
  value: undefined as Blueprint | undefined,
}));

vi.mock("@/services/fyAdminApi", () => ({
  useBlueprint: () => ({
    data: blueprint,
    isLoading: ref(false),
    isFetching: ref(false),
    isError: ref(false),
  }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    l: (value: string) => value,
  }),
}));

vi.mock("@/shared/composables/useMetaInfo", () => ({
  useMetaInfo: () => ({ updateMetaInfo: vi.fn() }),
}));

import BlueprintPage from "./[id].vue";

const record = (overrides: Partial<Blueprint> = {}): Blueprint => ({
  id: "1f4a9f7e-0000-0000-0000-000000000001",
  name: "Ballistic Cannon",
  slug: "cannon-s01",
  scKey: "bp_craft_cannon_s01",
  scRef: "1f4a9f7e-0000-0000-0000-0000000000ff",
  craftTime: 120,
  slotCount: 2,
  retired: false,
  sourceUnknown: false,
  craftableMissing: false,
  craftable: {
    type: "Component",
    id: "1f4a9f7e-0000-0000-0000-00000000000a",
    name: "Ballistic Cannon",
    slug: "ballistic-cannon",
  },
  build: { version: "4.10.1-live.1", environment: "live" },
  createdAt: "2026-09-01T00:00:00Z",
  updatedAt: "2026-09-02T00:00:00Z",
  ...overrides,
});

// `emptyVisible` is rendered because BaseTable shows the empty row *instead of*
// the records, so passing it unconditionally silently empties the table.
const tableStub = {
  props: ["records", "title", "emptyVisible"],
  template: `<div :data-empty="String(emptyVisible)">
    <span v-for="(row, index) in records" :key="index" class="row">{{
      JSON.stringify(row)
    }}</span>
  </div>`,
};

const detailStub = {
  props: ["details"],
  template: `<dl>
    <div v-for="detail in details" :key="detail.label" class="detail">
      <dt>{{ detail.label }}</dt>
      <dd>{{ detail.value }}</dd>
    </div>
  </dl>`,
};

const mountPage = async () => {
  const router: Router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: "/blueprints/",
        name: "admin-blueprints",
        component: { template: "<div />" },
      },
      {
        path: "/blueprints/:id/",
        name: "admin-blueprint",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({
    name: "admin-blueprint",
    params: { id: blueprint.value?.id ?? "unknown" },
  });
  await router.isReady();

  return mount(BlueprintPage, {
    global: {
      plugins: [router, VueQueryPlugin],
      stubs: {
        AsyncData: { template: "<div><slot name='resolved' /></div>" },
        BreadCrumbs: true,
        Heading: { template: "<div><slot /></div>" },
        BaseTable: tableStub,
        DetailList: detailStub,
      },
    },
  });
};

const rowsOf = (wrapper: Awaited<ReturnType<typeof mountPage>>, key: string) =>
  wrapper
    .findAll(`[data-test="blueprint-${key}"] .row`)
    .map((row) => JSON.parse(row.text()));

const detailFor = (
  wrapper: Awaited<ReturnType<typeof mountPage>>,
  label: string,
) =>
  wrapper
    .findAll('[data-test="blueprint-details"] .detail')
    .find((detail) => detail.find("dt").text() === label)
    ?.find("dd")
    .text();

describe("AdminBlueprintPage", () => {
  beforeEach(() => {
    blueprint.value = record();
  });

  it("flattens every slot's materials into one table", async () => {
    blueprint.value = record({
      costSlots: [
        {
          name: "Metals",
          scKey: "slot_metals",
          position: 1,
          options: [
            {
              type: "resource",
              quantity: 4,
              minQuality: 200,
              commodityKey: "titanium",
              commodity: { id: "c1", name: "Titanium", slug: "titanium" },
            },
            {
              type: "resource",
              quantity: 2,
              minQuality: null,
              commodityKey: "iron",
              commodity: null,
            },
          ],
          modifiers: [],
        },
      ],
    });

    const rows = rowsOf(await mountPage(), "materials");

    expect(rows).toHaveLength(2);
    expect(rows[0].slot).toBe("1 · Metals");
    expect(rows[0].material).toBe("Titanium");
    // `commodityKey` answers where the catalogue has no row, so a cost line
    // never renders nameless.
    expect(rows[1].material).toBe("iron");
  });

  it("renders a stat ramp per modifier", async () => {
    blueprint.value = record({
      costSlots: [
        {
          name: null,
          scKey: null,
          position: 2,
          options: [],
          modifiers: [
            {
              name: "Damage",
              propertyKey: "damage",
              unitFormat: "%d",
              ramp: "linear",
              startQuality: 100,
              endQuality: 900,
              modifierAtStart: 0.9,
              modifierAtEnd: 1.4,
              unit: "dmg",
              baseValue: 240,
            },
          ],
        },
      ],
    });

    const rows = rowsOf(await mountPage(), "stats");

    expect(rows).toHaveLength(1);
    // An unnamed slot falls back to its position alone.
    expect(rows[0].slot).toBe("2");
    expect(rows[0].quality).toBe("100 – 900");
    expect(rows[0].change).toBe("0.9 → 1.4 dmg");
  });

  it("names an unattributed source rather than leaving it blank", async () => {
    blueprint.value = record({
      sources: [
        {
          kind: "scenario",
          orgName: null,
          missionName: null,
          minStanding: null,
          maxStanding: null,
          minPoints: 18000,
          poolKey: "bp_missionreward_example",
          poolGroup: "xenothreat2rewards",
        },
      ],
    });

    const rows = rowsOf(await mountPage(), "sources");

    expect(rows[0].org).toBe("labels.blueprint.unattributed");
    expect(rows[0].standing).toBe("labels.blueprint.minPoints");
    expect(rows[0].pool).toBe("xenothreat2rewards / bp_missionreward_example");
  });

  it("says which build the facts came from and whether it is the current one", async () => {
    const wrapper = await mountPage();

    expect(detailFor(wrapper, "labels.admin.blueprints.build")).toBe(
      "4.10.1-live.1 (live)",
    );
    expect(detailFor(wrapper, "labels.admin.blueprints.state")).toBe(
      "labels.admin.blueprints.states.current",
    );
  });

  // BaseTable renders the empty row in place of the records, so a table told
  // "empty" while holding rows shows none of them.
  it("only claims a table is empty when it has no rows", async () => {
    blueprint.value = record({
      costSlots: [
        {
          name: "Metals",
          scKey: "slot_metals",
          position: 1,
          options: [
            {
              type: "resource",
              quantity: 4,
              minQuality: 200,
              commodityKey: "titanium",
              commodity: { id: "c1", name: "Titanium", slug: "titanium" },
            },
          ],
          modifiers: [],
        },
      ],
    });

    const wrapper = await mountPage();

    expect(
      wrapper
        .find('[data-test="blueprint-materials"]')
        .attributes("data-empty"),
    ).toBe("false");
    // Nothing fills these two, so they do say so.
    expect(
      wrapper.find('[data-test="blueprint-stats"]').attributes("data-empty"),
    ).toBe("true");
    expect(
      wrapper.find('[data-test="blueprint-sources"]').attributes("data-empty"),
    ).toBe("true");
  });

  it("states an output that is in no catalogue", async () => {
    blueprint.value = record({
      craftable: null,
      craftableMissing: true,
      retired: true,
    });

    const wrapper = await mountPage();

    expect(detailFor(wrapper, "labels.admin.blueprints.makes")).toBe(
      "labels.admin.blueprints.noOutput",
    );
    expect(detailFor(wrapper, "labels.admin.blueprints.state")).toBe(
      "labels.admin.blueprints.states.retired",
    );
  });
});

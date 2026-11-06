import { describe, expect, it, vi } from "vitest";
import { createMemoryHistory, createRouter } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HardpointCategoryEnum,
  HardpointGroupEnum,
  HardpointSourceEnum,
  type Hardpoint,
} from "@/services/fyApi";
import { hardpointCardFoldKey } from "@/frontend/components/Models/MetricsCard/fold";
import Component from "./index.vue";

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", component: { template: "<div />" } },
    {
      path: "/components/:slug",
      name: "component",
      component: { template: "<div />" },
    },
  ],
});

const generator = (id: string) =>
  ({
    id,
    groupKey: "shield",
    name: `hardpoint_shield_${id}`,
    source: HardpointSourceEnum.GAME_FILES,
    group: HardpointGroupEnum.SYSTEM,
    category: HardpointCategoryEnum.SHIELDGENERATOR,
    maxSize: 1,
    component: {
      id: "allstop",
      name: "AllStop",
      slug: "allstop",
      catalogued: true,
      typeData: {},
    },
  }) as unknown as Hardpoint;

const summaryRow = "[data-test='hardpoints-summary-row']";

const mountGroup = (fold?: { collapsed: () => boolean; toggle: () => void }) =>
  mountWithDefaults(
    defineComponent({
      components: { Group: Component },
      setup() {
        if (fold) provide(hardpointCardFoldKey, fold);

        return {
          group: HardpointGroupEnum.SYSTEM,
          hardpoints: [generator("a"), generator("b")],
        };
      },
      template: "<Group :group='group' :hardpoints='hardpoints' />",
    }),
    { plugins: [router] },
  );

describe("HardpointGroup", () => {
  it("shows the full rows, with no toggle, where nothing folds it", async () => {
    const wrapper = await mountGroup();

    expect(wrapper.find(summaryRow).exists()).toBe(false);
    expect(wrapper.find(".hardpoint-item").exists()).toBe(true);
    expect(wrapper.find("[data-test='metrics-card-collapse']").exists()).toBe(
      false,
    );
  });

  it("shows the summary rows while collapsed, keeping the catalogue link", async () => {
    const wrapper = await mountGroup({
      collapsed: () => true,
      toggle: vi.fn(),
    });
    const rows = wrapper.findAll(summaryRow);

    expect(rows).toHaveLength(1);
    expect(rows[0].text()).toContain("×2");
    expect(rows[0].find("[data-test='popover-trigger']").exists()).toBe(true);
    expect(rows[0].find("a").exists()).toBe(true);
    expect(wrapper.find(".hardpoint-item").exists()).toBe(false);
  });

  it("shows ship matrix cards as a summary, with nothing to expand", async () => {
    const wrapper = await mountWithDefaults(
      defineComponent({
        components: { Group: Component },
        setup() {
          provide(hardpointCardFoldKey, {
            collapsed: () => false,
            toggle: vi.fn(),
          });

          return {
            group: HardpointGroupEnum.SYSTEM,
            hardpoints: [generator("a")],
          };
        },
        template:
          "<Group :group='group' :hardpoints='hardpoints' summary-only />",
      }),
      { plugins: [router] },
    );

    expect(wrapper.find(summaryRow).exists()).toBe(true);
    expect(wrapper.find(".hardpoint-item").exists()).toBe(false);
    expect(wrapper.find("[data-test='metrics-card-collapse']").exists()).toBe(
      false,
    );
  });

  it("offers no toggle on a group with nothing to summarise", async () => {
    const wrapper = await mountWithDefaults(
      defineComponent({
        components: { Group: Component },
        setup() {
          provide(hardpointCardFoldKey, {
            collapsed: () => true,
            toggle: vi.fn(),
          });

          return {
            group: HardpointGroupEnum.SYSTEM,
            hardpoints: [
              {
                ...generator("a"),
                category: HardpointCategoryEnum.LIFESUPPORT,
              },
            ],
          };
        },
        template: "<Group :group='group' :hardpoints='hardpoints' />",
      }),
      { plugins: [router] },
    );

    expect(wrapper.find(".hardpoint-item").exists()).toBe(true);
    expect(wrapper.find("[data-test='metrics-card-collapse']").exists()).toBe(
      false,
    );
  });

  it("swaps in the full rows when expanded, under the same toggle", async () => {
    const toggle = vi.fn();
    const wrapper = await mountGroup({ collapsed: () => false, toggle });

    expect(wrapper.find(summaryRow).exists()).toBe(false);
    expect(wrapper.find(".hardpoint-item").exists()).toBe(true);

    await wrapper.find("[data-test='metrics-card-collapse']").trigger("click");

    expect(toggle).toHaveBeenCalledWith(HardpointGroupEnum.SYSTEM);
  });
});

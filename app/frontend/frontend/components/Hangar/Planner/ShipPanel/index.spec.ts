import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPlanSlotStateEnum,
  type HangarPlanAcquisition,
  type HangarPlanCandidate,
  type HangarPlanSlot,
} from "@/services/fyApi";
import type { HangarFlowTarget } from "@/frontend/components/Hangar/Planner/HangarFlow/types";
import Component from "./index.vue";

const comlinkEmit = vi.hoisted(() => vi.fn());
const routeDirty = vi.hoisted(() => ({ value: false }));
const livePlan = vi.hoisted(() => ({ value: undefined as unknown }));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangarPlan: () => ({ data: ref(livePlan.value) }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: comlinkEmit, on: vi.fn(), off: vi.fn() }),
}));

const view = vi.hoisted(() => (name: string) => async () => {
  const { defineComponent, h } = await import("vue");

  return {
    default: defineComponent({
      name,
      emits: ["done", "editSlot", "settings"],
      setup(_props, { expose }) {
        expose({
          get dirty() {
            return routeDirty.value;
          },
        });

        return () => h("div", { "data-test": `view-${name}` });
      },
    }),
  };
});

vi.mock(
  "@/frontend/components/Hangar/Planner/ShipPanel/StartView/index.vue",
  view("start"),
);
vi.mock(
  "@/frontend/components/Hangar/Planner/ShipPanel/EndView/index.vue",
  view("end"),
);
vi.mock(
  "@/frontend/components/Hangar/Planner/ShipPanel/RouteView/index.vue",
  view("route"),
);
vi.mock(
  "@/frontend/components/Hangar/Planner/ShipPanel/SlotView/index.vue",
  view("slot"),
);

const ship = {
  id: "carrack",
  name: "Carrack",
  slug: "carrack",
  onSale: true,
  ccuInto: "on_sale",
  ccuOutOf: "known",
  pledgePrice: 600,
} as const;

const slot = {
  id: "explorer",
  label: "Explorer",
  quantity: 1,
  position: 0,
  state: HangarPlanSlotStateEnum.DECIDED,
  filters: {},
  candidates: [],
  starts: [],
} as HangarPlanSlot;

const candidate = { id: "candidate", model: ship } as HangarPlanCandidate;
const acquisition = {
  id: "route",
  startModel: { ...ship, id: "cutlass", name: "Cutlass Black" },
  steps: [],
} as unknown as HangarPlanAcquisition;

const target = (attrs: Partial<HangarFlowTarget> = {}): HangarFlowTarget => ({
  key: "row",
  tab: "route",
  start: { slot, candidate, acquisition },
  route: { candidate, acquisition },
  end: { startName: "Cutlass Black", acquisition, slot },
  ...attrs,
});

const mount = (attrs: Partial<HangarFlowTarget> = {}) =>
  mountWithDefaults(Component, {
    props: { planId: "plan", target: target(attrs) },
  });

describe("Hangar/Planner/ShipPanel", () => {
  beforeEach(() => {
    livePlan.value = undefined;
    routeDirty.value = false;
    comlinkEmit.mockClear();
  });

  it("offers every side of the row as a tab and opens on the one asked for", async () => {
    const wrapper = await mount();

    expect(
      wrapper.findAll('[role="tab"]').map((tab) => tab.attributes("data-test")),
    ).toEqual([
      "hangar-plan-panel-tab-start",
      "hangar-plan-panel-tab-route",
      "hangar-plan-panel-tab-end",
    ]);
    expect(wrapper.find('[data-test="view-route"]').exists()).toBe(true);

    await wrapper
      .find('[data-test="hangar-plan-panel-tab-end"]')
      .trigger("click");

    expect(wrapper.find('[data-test="view-end"]').exists()).toBe(true);
    expect(wrapper.find("h2").text()).toBe("Pick where Cutlass Black ends up");
  });

  it("shows no tabs for a slot alone", async () => {
    const wrapper = await mount({
      tab: "slot",
      start: undefined,
      route: undefined,
      end: undefined,
      slot,
    });

    expect(wrapper.find('[role="tablist"]').exists()).toBe(false);
    expect(wrapper.find('[data-test="view-slot"]').exists()).toBe(true);
  });

  it("closes from its button, its backdrop and with Escape", async () => {
    const wrapper = await mount();

    await wrapper
      .find('[data-test="hangar-plan-panel-close"]')
      .trigger("click");
    await wrapper
      .find('[data-test="hangar-plan-panel"]')
      .trigger("keydown", { key: "Escape" });

    await wrapper
      .find('[data-test="hangar-plan-panel-backdrop"]')
      .trigger("click");

    expect(wrapper.emitted("close")).toHaveLength(3);
  });

  it("asks before leaving a route with edits not saved", async () => {
    routeDirty.value = true;
    const wrapper = await mount();

    await wrapper
      .find('[data-test="hangar-plan-panel-close"]')
      .trigger("click");

    expect(wrapper.emitted("close")).toBeUndefined();
    const [[event, options]] = comlinkEmit.mock.calls as [
      [string, { onConfirm: () => void }],
    ];
    expect(event).toBe("show-confirm");

    options.onConfirm();
    expect(wrapper.emitted("close")).toHaveLength(1);
  });

  it("closes once a view is done", async () => {
    const wrapper = await mount({ tab: "start" });

    wrapper.findComponent({ name: "start" }).vm.$emit("done");
    await flushPromises();

    expect(wrapper.emitted("close")).toHaveLength(1);
  });

  it("picks a start for the slot as the plan has it now", async () => {
    const shortlisted = {
      ...slot,
      candidates: [{ ...candidate, acquisitions: [] }],
    } as HangarPlanSlot;
    livePlan.value = { slots: [shortlisted] };

    const wrapper = await mount({
      tab: "start",
      start: { slot },
      route: undefined,
      end: undefined,
    });

    expect(
      wrapper.findComponent({ name: "start" }).vm.$attrs.slot,
    ).toStrictEqual(shortlisted);
  });

  it("edits the slot of a route's end in the same panel", async () => {
    const wrapper = await mount({ tab: "end" });

    wrapper.findComponent({ name: "end" }).vm.$emit("editSlot", slot);
    await flushPromises();

    expect(wrapper.find('[data-test="view-slot"]').exists()).toBe(true);
    expect(
      wrapper.find('[data-test="hangar-plan-panel-tab-slot"]').exists(),
    ).toBe(true);
  });
});

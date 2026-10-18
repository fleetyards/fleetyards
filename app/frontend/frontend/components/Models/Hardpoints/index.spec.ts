import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HardpointCategoryEnum,
  HardpointGroupEnum,
  HardpointSourceEnum,
  type Hardpoint,
  type Model,
} from "@/services/fyApi";
import Component from "./index.vue";

const queried = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModelHardpoints: (
    _slug: unknown,
    _params: unknown,
    options: { query: { enabled: () => boolean } },
  ) => {
    queried(options.query.enabled());

    return {
      data: ref([]),
      isLoading: ref(false),
      isFetching: ref(false),
      refetch: () => Promise.resolve(),
    };
  },
}));

const model = {
  slug: "retaliator",
  inGame: true,
  metrics: {},
  speeds: {},
} as unknown as Model;

const moduleSlot = {
  id: "front",
  name: "hardpoint_front_module",
  group: HardpointGroupEnum.SYSTEM,
  category: HardpointCategoryEnum.MODULE,
  source: HardpointSourceEnum.GAME_FILES,
  component: { id: "m1", name: "Cargo Module" },
  hardpoints: [],
} as unknown as Hardpoint;

describe("Hardpoints with a loadout's fitting", () => {
  it("lists the fitting read-only and leaves the hull's own hardpoints unasked for", async () => {
    queried.mockClear();

    const wrapper = await mountWithDefaults(Component, {
      props: { model, fitting: [moduleSlot] },
    });

    expect(queried).toHaveBeenCalledWith(false);
    expect(wrapper.text()).toContain("Cargo Module");
    expect(wrapper.find(".module-select-btn").exists()).toBe(false);
    expect(wrapper.find(".hardpoints__source").exists()).toBe(false);

    wrapper.unmount();
  });
});

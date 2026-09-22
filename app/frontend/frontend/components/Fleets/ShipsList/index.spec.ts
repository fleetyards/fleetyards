import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { beforeEach, describe, expect, it, vi } from "vitest";

/*
 * A mount test rather than an assertion about markup: this component's setup
 * reads its page out of `usePagination`, its params out of the page, and its
 * queries out of the params. Get that order wrong and setup throws before
 * anything renders -- which is how this list shipped broken once. Mounting is
 * the check; what it draws is covered elsewhere.
 */

const { emptyQuery } = vi.hoisted(() => ({
  // Reads every argument, which is the point: vue-query evaluates the params
  // when it builds the key, so a stub that ignored them would mount happily
  // over a params computed that throws.
  emptyQuery: (...args: unknown[]) => {
    args.forEach((arg) => {
      if (typeof arg === "function") {
        (arg as () => unknown)();
      } else if (arg && typeof arg === "object" && "value" in arg) {
        void (arg as { value: unknown }).value;
      }
    });

    return {
      data: { value: undefined },
      refetch: () => Promise.resolve(),
      isLoading: { value: false },
      isError: { value: false },
      isSuccess: { value: true },
    };
  },
}));

// Partial: the session store this component reaches through imports plenty
// more of the API module than the six queries replaced here.
vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<object>()),
  useFleetVehicles: emptyQuery,
  useFleetVehiclesStats: emptyQuery,
  useFleetModelCounts: emptyQuery,
}));

vi.mock("vue-router", () => ({
  useRoute: () => ({
    name: "fleet-ships",
    params: { slug: "merc" },
    query: {},
  }),
}));

vi.mock("@tanstack/vue-query", async (importOriginal) => ({
  ...(await importOriginal<object>()),
  useQueryClient: () => ({ invalidateQueries: vi.fn() }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toDollar: (value: number) => String(value),
    toUEC: (value: number) => String(value),
    toNumber: (value: number) => String(value),
  }),
}));

vi.mock("@/shared/composables/useFilters", () => ({
  useFilters: () => ({ getQuery: () => ({}) }),
}));

vi.mock("@/shared/composables/useSubscription", () => ({
  useSubscription: vi.fn(),
}));

vi.mock("@/frontend/composables/useVehicleSortFields", () => ({
  useVehicleSortFields: () => [],
}));

import Component from "./index.vue";
import type { Fleet } from "@/services/fyApi";

const fleet = {
  slug: "merc",
  name: "Mercenaries",
  publicFleet: true,
} as Fleet;

const mountWith = (props: { fleet: Fleet }) =>
  mount(Component, {
    props,
    shallow: true,
    global: { directives: { tooltip: () => {} } },
  });

describe("FleetShipsList", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("mounts for a whole fleet", () => {
    expect(mountWith({ fleet }).exists()).toBe(true);
  });

  // The stats query takes the filter now, which means another params object
  // evaluated during setup.
  it("mounts with the filter wired into the stats query", () => {
    expect(mountWith({ fleet }).exists()).toBe(true);
  });
});

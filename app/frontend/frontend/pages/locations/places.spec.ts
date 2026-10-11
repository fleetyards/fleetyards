import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useLocations: () => ({
    data: ref({
      items: [],
      meta: {
        pagination: {
          totalCount: 120,
          currentPage: 1,
          totalPages: 2,
          perPage: 60,
          defaultPerPage: 60,
          maxPerPage: 100,
          perPageSteps: [15, 30, 60, 90],
        },
      },
    }),
    error: ref(null),
    isPending: ref(false),
    isFetching: ref(false),
    isError: ref(false),
    isSuccess: ref(true),
    isLoading: ref(false),
    fetchStatus: ref("idle"),
    isRefetching: ref(false),
    refetch: vi.fn(),
  }),
}));

import PlacesPage from "./places.vue";

let mounted: { unmount: () => void } | undefined;

beforeEach(() => {
  document.body.innerHTML =
    '<div id="header-left"></div><div id="header-right"></div><div id="off-canvas-content"></div><div id="app"></div>';
});

afterEach(() => {
  mounted?.unmount();
  mounted = undefined;
});

const mount = async () => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/locations/places", name: "locations-places", component: {} },
      { path: "/locations", name: "locations", component: {} },
      { path: "/", name: "home", component: {} },
    ],
  });

  await router.push("/locations/places");

  const wrapper = await mountWithDefaults(PlacesPage, {
    plugins: [router],
    attachTo: document.getElementById("app")!,
  });

  mounted = wrapper;

  await flushPromises();

  return wrapper;
};

describe("places page", () => {
  it("offers the page sizes the list sends", async () => {
    const wrapper = await mount();

    const dropdowns = wrapper.findAllComponents({ name: "PerPageDropdown" });

    expect(dropdowns.length).toBeGreaterThan(0);
    expect(dropdowns[0].props("steps")).toEqual([15, 30, 60, 90]);
  });
});

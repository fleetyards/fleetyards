import { afterEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const kraken = {
  slug: "kraken",
  name: "Kraken Haulers",
  logo: { smallUrl: "/kraken.png" },
};
const drake = { slug: "drake-den", name: "Drake Den", logo: null };

vi.mock("@/services/fyApi", async () => ({
  ...(await vi.importActual<Record<string, unknown>>("@/services/fyApi")),
  useMyFleets: () => ({ data: computed(() => [kraken, drake]) }),
}));

import FleetsNav from "./index.vue";

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const Stub = { render: () => null };

const mountFleetsNav = async (authenticated: boolean) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/fleets/:slug", name: "fleet", component: Stub },
      { path: "/fleets/directory", name: "fleet-directory", component: Stub },
      { path: "/fleets/add", name: "fleet-add", component: Stub },
      { path: "/fleets/preview", name: "fleet-preview", component: Stub },
    ],
  });

  await router.push("/fleets/directory");

  wrapper = await mountWithDefaults(FleetsNav, {
    plugins: [router],
    initialState: { nav: { slim: false }, session: { authenticated } },
  });

  return wrapper;
};

describe("FleetsNav", () => {
  it("lists a signed-in reader's fleets", async () => {
    const nav = await mountFleetsNav(true);

    expect(nav.find('[data-test="fleets-nav-fleet-kraken"]').exists()).toBe(
      true,
    );
    expect(nav.find('[data-test="fleets-nav-fleet-drake-den"]').exists()).toBe(
      true,
    );
  });

  it("lists no fleets for a guest", async () => {
    const nav = await mountFleetsNav(false);

    expect(nav.find('[data-test="fleets-nav-fleet-kraken"]').exists()).toBe(
      false,
    );
  });
});

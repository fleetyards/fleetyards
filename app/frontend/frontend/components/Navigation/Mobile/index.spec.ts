import { afterEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const kraken = {
  slug: "kraken",
  name: "Kraken Haulers",
  logo: null,
  myFleet: true,
  publicFleet: false,
};

vi.mock("@/services/fyApi", async () => ({
  ...(await vi.importActual<Record<string, unknown>>("@/services/fyApi")),
  useFleet: (slug: { value: string }) => ({
    data: computed(() => (slug.value === "kraken" ? kraken : undefined)),
  }),
  usePublicFleet: () => ({ data: computed(() => undefined) }),
  useMyFleets: () => ({
    data: computed(() => []),
    isPending: computed(() => false),
  }),
  useNotificationsUnreadCount: () => ({ data: computed(() => ({ count: 0 })) }),
}));

vi.mock("@/frontend/composables/useFleetNavAccess", () => ({
  useFleetNavAccess: () => ({
    showContractsNav: computed(() => false),
    showEventsNav: computed(() => false),
    eventsNavRoute: computed(() => "fleet-events"),
    contractsNavActive: computed(() => false),
    eventsNavActive: computed(() => false),
  }),
}));

import MobileNavigation from "./index.vue";

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const Stub = { render: () => null };

const mountTabs = async (path: string, fleetSlug: string | null) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/ships", name: "ships", component: Stub },
      { path: "/hangar", name: "hangar", component: Stub },
      { path: "/notifications", name: "notifications", component: Stub },
      { path: "/settings/profile", name: "settings-profile", component: Stub },
      { path: "/fleets/:slug", name: "fleet", component: Stub },
      { path: "/fleets/:slug/ships", name: "fleet-ships", component: Stub },
      {
        path: "/fleets/:slug/members",
        name: "fleet-members",
        component: Stub,
      },
    ],
  });

  await router.push(path);

  wrapper = await mountWithDefaults(MobileNavigation, {
    plugins: [router],
    initialState: {
      session: {
        authenticated: true,
        currentUser: { id: "user-1", username: "torlek" },
      },
      navContext: { fleetSlug },
    },
  });

  return wrapper;
};

const fleetTab = (tabs: VueWrapper) =>
  tabs
    .findAllComponents({ name: "NavItem" })
    .find((item) => item.props("label") === "Kraken Haulers");

describe("Mobile navigation", () => {
  // The sidebar keeps the fleet on an account page, and the tabs have to agree.
  it("keeps the fleet's tabs on an account page opened from it", async () => {
    const tabs = await mountTabs("/settings/profile", "kraken");

    expect(fleetTab(tabs)).toBeDefined();
  });

  it("shows the personal tabs anywhere else", async () => {
    const tabs = await mountTabs("/ships", "kraken");

    expect(fleetTab(tabs)).toBeUndefined();
  });
});

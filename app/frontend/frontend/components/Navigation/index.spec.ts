import { describe, expect, it, vi } from "vitest";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const { Stub, named, coarsePointer, ios } = vi.hoisted(() => {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const vue = require("vue");

  return {
    Stub: vue.defineComponent({ name: "Stub", render: () => vue.h("div") }),
    named: (name: string) =>
      vue.defineComponent({
        name,
        render: () => vue.h("li", { "data-test": name }),
      }),
    coarsePointer: vue.ref(false),
    ios: vue.ref(false),
  };
});

vi.mock("./FleetNav/index.vue", () => ({ default: named("fleet-nav") }));
vi.mock("./FleetsNav/index.vue", () => ({ default: named("fleets-nav") }));
vi.mock("./ContextSwitcher/index.vue", () => ({
  default: named("context-switcher"),
}));
vi.mock("./AccountMenu/index.vue", () => ({ default: named("account-menu") }));
vi.mock("./ToolsNav/index.vue", () => ({ default: Stub }));
vi.mock("@/frontend/components/Navigation/CatalogueNav/index.vue", () => ({
  default: Stub,
}));
vi.mock("@/frontend/components/ScDataSource/index.vue", () => ({
  default: Stub,
}));
vi.mock("@/frontend/composables/useInstallPrompt", () => ({
  useInstallPrompt: () => ({
    canInstall: ref(true),
    isIos: ios,
    install: vi.fn(),
  }),
}));
vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => false }),
}));
vi.mock("@vueuse/core", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@vueuse/core")>()),
  useMediaQuery: () => coarsePointer,
}));

import Navigation from "./index.vue";
import { NAV_ENTRIES } from "./entries";

// Everything the navigation links to, plus the pages it is asked about.
const routes = [
  "hangar",
  "hangar-wishlist",
  "hangar-preview",
  "settings-hangar",
  "settings",
  "ships",
  "compare",
  "locations",
  "locations-places",
  "location",
  "shop",
  "images",
  "stats",
  "cart",
  "notifications",
  "settings-profile",
  "login",
  "visual-tests",
  ...NAV_ENTRIES.map((entry) => entry.route).filter((name) => name !== "home"),
]
  .filter((name, index, names) => names.indexOf(name) === index)
  .map((name) => ({ path: `/${name}`, name, component: Stub }));

const signedIn = {
  session: {
    authenticated: true,
    currentUser: { id: "user-1", username: "torlek" },
  },
};

const mountNavigation = async (
  routeName: string,
  initialState: Record<string, unknown> = {},
) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/fleets/:slug", name: "fleet", component: Stub },
      ...routes,
    ],
  });

  await router.push(
    routeName === "fleet"
      ? { name: routeName, params: { slug: "kraken" } }
      : { name: routeName },
  );
  await router.isReady();

  return mountWithDefaults(Navigation, {
    plugins: [router],
    // Expanded, so a section's rows are rendered in place rather than in a
    // flyout that only exists while it is open.
    initialState: {
      hangar: { preview: false },
      nav: { slim: false },
      ...initialState,
    },
  });
};

const hangarItem = async (routeName: string) => {
  const wrapper = await mountNavigation(routeName);

  return wrapper
    .findAllComponents({ name: "NavItem" })
    .find((item) => item.props("icon") === "fa-duotone fa-warehouse")!;
};

const locationsItem = async (routeName: string) => {
  const wrapper = await mountNavigation(routeName);

  return wrapper
    .findAllComponents({ name: "NavItem" })
    .find((item) => item.props("icon") === "fa-duotone fa-planet-ringed")!;
};

describe("Navigation", () => {
  it("marks the places on every place and shop page", async () => {
    for (const name of ["locations", "locations-places", "location", "shop"]) {
      expect((await locationsItem(name)).props("active")).toBe(true);
    }

    expect((await locationsItem("ships")).props("active")).toBe(false);
  });

  it("marks the hangar while a hangar page is open", async () => {
    expect((await hangarItem("hangar")).props("active")).toBe(true);
    expect((await hangarItem("hangar-wishlist")).props("active")).toBe(true);
  });

  // Its name ends in "hangar", and a match anywhere in the name lit the hangar
  // up next to the settings entry that is actually open.
  it("leaves the hangar unmarked on the hangar settings", async () => {
    expect((await hangarItem("settings-hangar")).props("active")).toBe(false);
  });

  // The hangar's pages were linked only from the hangar page itself.
  it("lists the hangar's own pages for a signed-in reader", async () => {
    const wrapper = await mountNavigation("ships", signedIn);

    for (const key of [
      "hangar-wishlist",
      "hangar-stats",
      "hangar-assets-menu",
      "hangar-pledge-items-menu",
    ]) {
      expect(wrapper.find(`[data-test="nav-${key}"]`).exists()).toBe(true);
    }
  });

  // Only the sub-section the open page is in unfolds.
  it("opens the sub-section of the page that is open", async () => {
    const wrapper = await mountNavigation("hangar-paints", signedIn);

    const section = (key: string) =>
      wrapper
        .findAllComponents({ name: "NavItem" })
        .find((item) => item.props("menuKey") === key)!;

    expect(section("hangar-pledge-items-menu").props("submenuActive")).toBe(
      true,
    );
    expect(section("hangar-assets-menu").props("submenuActive")).toBe(false);
    expect(section("hangar-pledge-items-menu").props("overlay")).toBe(true);
  });

  it("leaves out a hangar page whose feature is off", async () => {
    const wrapper = await mountNavigation("ships", signedIn);

    expect(wrapper.find('[data-test="nav-hangar-plans"]').exists()).toBe(false);
  });

  // A signed-in reader reaches their fleets from the switcher instead.
  it("gives a signed-in reader the switcher and the account menu", async () => {
    const wrapper = await mountNavigation("ships", signedIn);

    expect(wrapper.find('[data-test="context-switcher"]').exists()).toBe(true);
    expect(wrapper.find('[data-test="account-menu"]').exists()).toBe(true);
    expect(wrapper.find('[data-test="fleets-nav"]').exists()).toBe(false);
  });

  it("gives a guest the fleets section and the login", async () => {
    const wrapper = await mountNavigation("ships");

    expect(wrapper.find('[data-test="context-switcher"]').exists()).toBe(false);
    expect(wrapper.find('[data-test="fleets-nav"]').exists()).toBe(true);
    expect(wrapper.find('[data-test="nav-login"]').exists()).toBe(true);
  });

  // The switcher is the way out of a fleet, so nothing else is listed there.
  it("shows only the fleet's own pages inside a fleet", async () => {
    const wrapper = await mountNavigation("fleet", signedIn);

    expect(wrapper.find('[data-test="fleet-nav"]').exists()).toBe(true);
    expect(wrapper.find('[data-test="nav-home"]').exists()).toBe(false);
    expect(wrapper.find('[data-test="nav-hangar-menu"]').exists()).toBe(false);
  });

  // An account page is nobody's hangar or fleet, so it leaves the reader where
  // they were.
  it("keeps the fleet on an account page", async () => {
    const wrapper = await mountNavigation("settings-profile", {
      ...signedIn,
      navContext: { fleetSlug: "kraken" },
    });

    expect(wrapper.find('[data-test="fleet-nav"]').exists()).toBe(true);
    expect(wrapper.find('[data-test="nav-home"]').exists()).toBe(false);
  });

  it("leaves the fleet for any other page", async () => {
    const wrapper = await mountNavigation("ships", {
      ...signedIn,
      navContext: { fleetSlug: "kraken" },
    });

    expect(wrapper.find('[data-test="fleet-nav"]').exists()).toBe(false);
    expect(wrapper.find('[data-test="nav-home"]').exists()).toBe(true);
  });

  it("offers the install on a touch device", async () => {
    coarsePointer.value = true;

    const wrapper = await mountNavigation("ships");

    expect(wrapper.find('[data-test="install-app"]').exists()).toBe(true);
  });

  it("leaves the install to the browser on desktop", async () => {
    coarsePointer.value = false;
    ios.value = false;

    const wrapper = await mountNavigation("ships");

    expect(wrapper.find('[data-test="install-app"]').exists()).toBe(false);
  });

  // Safari has no install button of its own, whatever pointer the iPad reports.
  it("offers the install on an iPad with a trackpad", async () => {
    coarsePointer.value = false;
    ios.value = true;

    const wrapper = await mountNavigation("ships");

    expect(wrapper.find('[data-test="install-app"]').exists()).toBe(true);
  });
});

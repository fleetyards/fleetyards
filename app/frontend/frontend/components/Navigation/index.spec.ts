import { describe, expect, it, vi } from "vitest";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const { Stub, coarsePointer, ios } = vi.hoisted(() => {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const vue = require("vue");

  return {
    Stub: vue.defineComponent({ name: "Stub", render: () => vue.h("div") }),
    coarsePointer: vue.ref(false),
    ios: vue.ref(false),
  };
});

vi.mock("./FleetNav/index.vue", () => ({ default: Stub }));
vi.mock("./NotificationsNav/index.vue", () => ({ default: Stub }));
vi.mock("./FleetsNav/index.vue", () => ({ default: Stub }));
vi.mock("./ToolsNav/index.vue", () => ({ default: Stub }));
vi.mock("@/frontend/components/Navigation/CatalogueNav/index.vue", () => ({
  default: Stub,
}));
vi.mock("@/frontend/components/ScDataSource/index.vue", () => ({
  default: Stub,
}));
vi.mock("@/frontend/composables/usePendingFriendRequests", () => ({
  usePendingFriendRequests: () => ({ count: ref(0) }),
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
  "login",
  "visual-tests",
  ...NAV_ENTRIES.map((entry) => entry.route).filter((name) => name !== "home"),
]
  .filter((name, index, names) => names.indexOf(name) === index)
  .map((name) => ({ path: `/${name}`, name, component: Stub }));

const signedIn = (navFavorites: string[] = []) => ({
  session: {
    authenticated: true,
    currentUser: { id: "user-1", username: "torlek", navFavorites },
  },
});

const mountNavigation = async (
  routeName: string,
  initialState: Record<string, unknown> = {},
) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/", name: "home", component: Stub }, ...routes],
  });

  await router.push({ name: routeName });
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
    const wrapper = await mountNavigation("ships", signedIn());

    for (const key of ["hangar-wishlist", "hangar-stats", "hangar-paints"]) {
      expect(wrapper.find(`[data-test="nav-${key}"]`).exists()).toBe(true);
    }
  });

  it("leaves out a hangar page whose feature is off", async () => {
    const wrapper = await mountNavigation("ships", signedIn());

    expect(wrapper.find('[data-test="nav-hangar-plans"]').exists()).toBe(false);
  });

  it("shows no favorites section while nothing is pinned", async () => {
    const wrapper = await mountNavigation("ships", signedIn());

    expect(wrapper.find('[data-test="nav-favorites-heading"]').exists()).toBe(
      false,
    );
  });

  it("puts the pinned pages at the top, in the order they were pinned", async () => {
    const wrapper = await mountNavigation(
      "ships",
      signedIn(["trade-routes", "hangar-wishlist", "no-such-page"]),
    );

    expect(wrapper.find('[data-test="nav-favorites-heading"]').exists()).toBe(
      true,
    );

    const pinned = wrapper
      .findAllComponents({ name: "AppNavigationEntryItem" })
      .map((item) => item.props("entry").key);

    expect(pinned.slice(0, 3)).toEqual([
      "home",
      "trade-routes",
      "hangar-wishlist",
    ]);
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

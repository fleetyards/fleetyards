import { describe, expect, it, vi } from "vitest";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const { Stub } = vi.hoisted(() => {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const { defineComponent, h } = require("vue");

  return {
    Stub: defineComponent({ name: "Stub", render: () => h("div") }),
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

import Navigation from "./index.vue";

// Everything the navigation links to, plus the pages it is asked about.
const routes = [
  "hangar",
  "hangar-wishlist",
  "hangar-preview",
  "settings-hangar",
  "settings",
  "ships",
  "compare",
  "images",
  "stats",
  "login",
  "visual-tests",
].map((name) => ({ path: `/${name}`, name, component: Stub }));

const hangarItem = async (routeName: string) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/", name: "home", component: Stub }, ...routes],
  });

  await router.push({ name: routeName });
  await router.isReady();

  const wrapper = await mountWithDefaults(Navigation, {
    plugins: [router],
    initialState: { hangar: { preview: false } },
  });

  return wrapper
    .findAllComponents({ name: "NavItem" })
    .find((item) => item.props("icon") === "fa-duotone fa-warehouse")!;
};

describe("Navigation", () => {
  it("marks the hangar while a hangar page is open", async () => {
    expect((await hangarItem("hangar")).props("active")).toBe(true);
    expect((await hangarItem("hangar-wishlist")).props("active")).toBe(true);
  });

  // Its name ends in "hangar", and a match anywhere in the name lit the hangar
  // up next to the settings entry that is actually open.
  it("leaves the hangar unmarked on the hangar settings", async () => {
    expect((await hangarItem("settings-hangar")).props("active")).toBe(false);
  });
});

import { afterEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const { unread, pending, cartQuantity } = vi.hoisted(() => {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const vue = require("vue");

  return {
    unread: vue.ref(0),
    pending: vue.ref(0),
    cartQuantity: vue.ref(0),
  };
});

vi.mock("@/services/fyApi", async () => ({
  ...(await vi.importActual<Record<string, unknown>>("@/services/fyApi")),
  useNotificationsUnreadCount: () => ({
    data: computed(() => ({ count: unread.value })),
  }),
  useCart: () => ({
    data: computed(() => ({ totals: { quantity: cartQuantity.value } })),
  }),
}));

vi.mock("@/frontend/composables/usePendingFriendRequests", () => ({
  usePendingFriendRequests: () => ({ count: pending }),
}));

import AccountMenu from "./index.vue";

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  unread.value = 0;
  pending.value = 0;
  cartQuantity.value = 0;
});

const Stub = { render: () => null };

const mountMenu = async (props: Record<string, unknown> = {}) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: ["home", "notifications", "cart", "settings", "login"].map(
      (name) => ({ path: `/${name}`, name, component: Stub }),
    ),
  });

  await router.push("/home");

  wrapper = await mountWithDefaults(AccountMenu, {
    props,
    plugins: [router],
    initialState: {
      nav: { slim: false },
      session: {
        authenticated: true,
        currentUser: { id: "user-1", username: "torlek", rsiHandle: null },
      },
    },
  });

  return wrapper;
};

const trigger = (menu: VueWrapper) => menu.get('[data-test="user-menu"]');

const openMenu = async (menu: VueWrapper) => {
  await trigger(menu).trigger("click");
};

describe("AccountMenu", () => {
  it("names the account on its trigger", async () => {
    const menu = await mountMenu();

    expect(trigger(menu).text()).toContain("torlek");
  });

  // Both are waiting on the reader, and both are only reachable from inside.
  it("adds unread notifications and friend requests on the avatar", async () => {
    unread.value = 3;
    pending.value = 1;

    const menu = await mountMenu();

    expect(menu.get('[data-test="user-menu-badge"]').text()).toBe("4");
  });

  it("leaves the cart out of the avatar's count", async () => {
    cartQuantity.value = 2;

    const menu = await mountMenu();

    expect(menu.find('[data-test="user-menu-badge"]').exists()).toBe(false);

    await openMenu(menu);

    expect(menu.get('[data-test="cart-nav"]').text()).toContain("2");
  });

  it("lists the account's pages once opened", async () => {
    const menu = await mountMenu();

    await openMenu(menu);

    for (const id of [
      "nav-notifications",
      "cart-nav",
      "nav-settings",
      "nav-logout",
    ]) {
      expect(menu.find(`[data-test="${id}"]`).exists()).toBe(true);
    }

    expect(menu.find('[data-test="nav-rsi-profile"]').exists()).toBe(false);
    expect(menu.find('[data-test="install-app"]').exists()).toBe(false);
  });

  it("offers the install when the navigation says so", async () => {
    const menu = await mountMenu({ showInstall: true });

    await openMenu(menu);
    await menu.get('[data-test="install-app"]').trigger("click");

    expect(menu.emitted("install")).toHaveLength(1);
  });
});

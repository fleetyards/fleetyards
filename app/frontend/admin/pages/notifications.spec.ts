import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { LONG_PRESS_MS } from "@/shared/composables/useLongPress";
import type { AdminNotification } from "@/services/fyAdminApi";

const notification = (id: string): AdminNotification => ({
  id,
  title: `Notification ${id}`,
  notificationType: "paints_import",
  severity: "info",
  occurrences: 1,
  lastOccurredAt: "2026-08-01T00:00:00Z",
  read: true,
  archived: false,
  expiresAt: "2026-09-01T00:00:00Z",
  createdAt: "2026-08-01T00:00:00Z",
  updatedAt: "2026-08-01T00:00:00Z",
});

const settled = (data: unknown) => ({
  data: ref(data),
  error: ref(null),
  isPending: ref(false),
  isFetching: ref(false),
  isError: ref(false),
  isSuccess: ref(true),
  fetchStatus: ref("idle"),
  isLoading: ref(false),
  isRefetching: ref(false),
  refetch: vi.fn(),
});

vi.mock("@/services/fyAdminApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useAdminNotifications: () =>
    settled({
      items: [notification("1"), notification("2")],
      meta: { pagination: { totalCount: 2, currentPage: 1, totalPages: 1 } },
    }),
  useAdminNotificationsUnreadCount: () => settled({ count: 0 }),
}));

import AdminNotificationsPage from "./notifications.vue";

const touch = (type: string, clientX?: number) => {
  const event = new Event(type, { bubbles: true, cancelable: true });

  Object.defineProperty(event, "touches", {
    value: clientX === undefined ? [] : [{ clientX, clientY: 0 }],
  });

  return event;
};

const headerLeft = () => document.getElementById("header-left")!;

// jsdom lays nothing out, so its document is 0px wide and every mount is a
// phone - which is the layout these tests are about.
let mounted: { unmount: () => void } | undefined;

const mount = async () => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/notifications", name: "admin-notifications", component: {} },
      {
        path: "/announcements",
        name: "admin-announcements",
        component: {},
      },
    ],
  });

  await router.push("/notifications");

  const wrapper = await mountWithDefaults(AdminNotificationsPage, {
    plugins: [router],
    attachTo: document.getElementById("app")!,
  });

  await flushPromises();

  mounted = wrapper;

  return wrapper;
};

type Mounted = Awaited<ReturnType<typeof mount>>;

const hold = async (wrapper: Mounted, index: number) => {
  const row = wrapper.findAll(".notification-item")[index].element;

  row.dispatchEvent(touch("touchstart", 200));
  vi.advanceTimersByTime(LONG_PRESS_MS);
  row.dispatchEvent(touch("touchend"));

  await flushPromises();
};

beforeEach(() => {
  document.body.innerHTML =
    '<div id="header-left"></div><div id="header-right"></div><div id="off-canvas-content"></div><div id="app"></div>';

  vi.useFakeTimers();
});

afterEach(() => {
  mounted?.unmount();
  mounted = undefined;
  vi.useRealTimers();
});

describe("AdminNotificationsPage on a phone", () => {
  it("shows the search in the header and no checkboxes until a row is held", async () => {
    const wrapper = await mount();

    expect(headerLeft().querySelector('input[name="search"]')).not.toBeNull();
    expect(headerLeft().querySelector('[data-test="bulk-exit"]')).toBeNull();
    expect(wrapper.find('[data-test="notification-checkbox"]').exists()).toBe(
      false,
    );
  });

  it("hands the header to the selection once a row is held", async () => {
    const wrapper = await mount();

    await hold(wrapper, 0);

    expect(headerLeft().querySelector('input[name="search"]')).toBeNull();
    expect(
      headerLeft().querySelector('[data-test="bulk-exit"]'),
    ).not.toBeNull();
    expect(
      document.querySelector('[data-test="notifications-menu"]'),
    ).toBeNull();
    expect(wrapper.findAll('[data-test="notification-checkbox"]')).toHaveLength(
      2,
    );
  });

  it("picks a tapped row while selecting instead of opening it", async () => {
    const wrapper = await mount();

    await hold(wrapper, 0);
    vi.advanceTimersByTime(1000);
    await wrapper
      .findAll('[data-test="notification-select"]')[1]
      .trigger("click");

    const checked = wrapper
      .findAll<HTMLInputElement>('[data-test="notification-checkbox"] input')
      .map((input) => input.element.checked);

    expect(checked).toEqual([true, true]);
    expect(wrapper.find(".notifications--reading").exists()).toBe(false);
  });

  it("gives the header back to the search when the selection is cleared", async () => {
    const wrapper = await mount();

    await hold(wrapper, 0);
    (
      headerLeft().querySelector('[data-test="bulk-exit"]') as HTMLElement
    ).click();
    await flushPromises();

    expect(headerLeft().querySelector('input[name="search"]')).not.toBeNull();
    expect(headerLeft().querySelector('[data-test="bulk-exit"]')).toBeNull();
    expect(
      document.querySelector('[data-test="notifications-menu"]'),
    ).not.toBeNull();
    expect(wrapper.find('[data-test="notification-checkbox"]').exists()).toBe(
      false,
    );
  });
});

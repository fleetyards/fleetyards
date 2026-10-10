import { flushPromises, mount } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { QueryClient, VueQueryPlugin } from "@tanstack/vue-query";
import { useNotificationsStore } from "@/shared/stores/notifications";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  AdminNotificationSeverityEnum,
  type AdminNotification,
} from "@/services/fyAdminApi";
import type { AdminNotificationsData } from "@/services/fyCableAdmin/channels/AdminNotificationsChannel";

interface Handler {
  received: (message: AdminNotificationsData) => void;
  connected: (event: { reconnect: boolean }) => void;
}

const handlers: Handler[] = [];

const listed = vi.fn();

vi.mock("@/shared/composables/useSubscription", () => ({
  useSubscription: (options: Handler) => {
    handlers.push(options);
  },
}));

vi.mock("@/services/fyAdminApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyAdminApi")>()),
  adminNotifications: (...args: unknown[]) => listed(...args),
}));

const { useAdminNotificationUpdates, useAdminNotificationToasts } =
  await import("./useAdminNotificationUpdates");

const notification = (attrs: Partial<AdminNotification> = {}) =>
  ({
    id: "a",
    title: "a",
    severity: AdminNotificationSeverityEnum.INFO,
    ...attrs,
  }) as AdminNotification;

const wrappers: ReturnType<typeof mount>[] = [];

const render = () => {
  let toasts!: ReturnType<typeof useAdminNotificationToasts>;
  let notifications!: ReturnType<typeof useAppNotifications>;

  wrappers.push(
    mount(
      defineComponent({
        setup() {
          useAdminNotificationUpdates(ref(true));
          toasts = useAdminNotificationToasts();
          notifications = useAppNotifications();

          return () => h("div");
        },
      }),
      {
        global: {
          plugins: [[VueQueryPlugin, { queryClient: new QueryClient() }]],
        },
      },
    ),
  );

  return {
    toasts,
    notifications,
    receive: handlers[0].received,
    reconnect: () => handlers[0].connected({ reconnect: true }),
  };
};

const messages = () => useNotificationsStore().messages;

const texts = () => messages().map(({ text }) => text);

beforeEach(() => {
  handlers.length = 0;
  listed.mockReset();
  setActivePinia(createPinia());
});

afterEach(() => {
  wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
});

describe("useAdminNotificationUpdates", () => {
  it("lets a warning toast go on its own", () => {
    const { receive } = render();

    receive(notification({ severity: AdminNotificationSeverityEnum.WARNING }));

    expect(messages()[0].timeout).toBe(10_000);
  });

  it("takes down the toasts of the settled notifications only", () => {
    const { receive } = render();

    receive(notification({ id: "a", title: "a" }));
    receive(notification({ id: "b", title: "b" }));

    receive({ settledIds: ["a"] });

    expect(texts()).toEqual(["b"]);
  });

  it("takes down the toasts settled while the socket was down", async () => {
    const { receive, reconnect } = render();

    receive(notification({ id: "a", title: "a" }));
    receive(notification({ id: "b", title: "b" }));

    listed.mockResolvedValue({ items: [{ id: "b" }] });

    reconnect();
    await flushPromises();

    expect(listed).toHaveBeenCalledWith(
      expect.objectContaining({ q: { idIn: ["a", "b"], readAtNull: true } }),
    );
    expect(texts()).toEqual(["b"]);
  });

  it("replaces the toast of a repeated report", () => {
    const { receive } = render();

    receive(notification({ title: "first" }));
    receive(notification({ title: "again" }));

    expect(texts()).toEqual(["again"]);
  });
});

describe("useAdminNotificationToasts", () => {
  it("leaves toasts of other senders alone", () => {
    const { toasts, notifications } = render();

    notifications.displayInfo({ text: "a", tag: "admin-notification:a" });
    notifications.displaySuccess({ text: "saved" });

    toasts.dismiss(["a"]);

    expect(texts()).toEqual(["saved"]);
  });
});

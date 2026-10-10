import { mount } from "@vue/test-utils";
import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { useNotificationsStore } from "@/shared/stores/notifications";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useAdminNotificationToasts } from "./useAdminNotificationUpdates";

const render = () => {
  let toasts!: ReturnType<typeof useAdminNotificationToasts>;
  let notifications!: ReturnType<typeof useAppNotifications>;

  mount(
    defineComponent({
      setup() {
        toasts = useAdminNotificationToasts();
        notifications = useAppNotifications();

        return () => h("div");
      },
    }),
  );

  return { toasts, notifications };
};

const texts = () => useNotificationsStore().messages.map(({ text }) => text);

describe("useAdminNotificationToasts", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("dismisses only the toasts of the notifications read", () => {
    const { toasts, notifications } = render();

    notifications.displayInfo({ text: "a", tag: "admin-notification:a" });
    notifications.displayInfo({ text: "b", tag: "admin-notification:b" });

    toasts.dismiss(["a"]);

    expect(texts()).toEqual(["b"]);
  });

  it("dismisses every notification toast and nothing else", () => {
    const { toasts, notifications } = render();

    notifications.displayInfo({ text: "a", tag: "admin-notification:a" });
    notifications.displaySuccess({ text: "saved" });

    toasts.dismissAll();

    expect(texts()).toEqual(["saved"]);
  });
});

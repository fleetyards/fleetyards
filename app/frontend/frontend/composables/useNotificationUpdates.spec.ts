import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { useNotificationsStore } from "@/shared/stores/notifications";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  notificationToastTag,
  useNotificationToasts,
} from "./useNotificationUpdates";

const texts = () => useNotificationsStore().messages.map(({ text }) => text);

beforeEach(() => {
  setActivePinia(createPinia());
});

describe("useNotificationToasts", () => {
  const announce = () => {
    const { displayMessage, displaySuccess } = useAppNotifications();

    displayMessage({ text: "a", tag: notificationToastTag("a") });
    displayMessage({ text: "b", tag: notificationToastTag("b") });
    displaySuccess({ text: "saved" });
  };

  it("takes down the toasts of the given notifications only", () => {
    announce();

    useNotificationToasts().dismiss(["a"]);

    expect(texts()).toEqual(["b", "saved"]);
  });

  it("takes down every notification toast without ids", () => {
    announce();

    useNotificationToasts().dismiss();

    expect(texts()).toEqual(["saved"]);
  });
});

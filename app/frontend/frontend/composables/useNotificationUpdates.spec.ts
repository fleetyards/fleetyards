import { beforeEach, describe, expect, it, vi } from "vitest";
import { useQueryClient } from "@tanstack/vue-query";
import { createPinia, setActivePinia } from "pinia";
import { useNotificationsStore } from "@/shared/stores/notifications";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { getMyFleetsQueryKey, type Notification } from "@/services/fyApi";
import {
  notificationToastTag,
  useNotificationInvalidation,
  useNotificationToasts,
} from "./useNotificationUpdates";

vi.mock("@tanstack/vue-query", async (importOriginal) => ({
  ...(await importOriginal<object>()),
  useQueryClient: vi.fn(),
}));

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

describe("useNotificationInvalidation", () => {
  const invalidateQueries = vi.fn();

  const notified = (notificationType: string) =>
    ({ notificationType }) as unknown as Notification;

  beforeEach(() => {
    invalidateQueries.mockClear();
    vi.mocked(useQueryClient).mockReturnValue({
      invalidateQueries,
    } as unknown as ReturnType<typeof useQueryClient>);
  });

  it.each(["fleet_request_accepted", "fleet_joined_by_discord_role"])(
    "refreshes the reader's fleets on %s",
    (type) => {
      useNotificationInvalidation().invalidateMyFleets(notified(type));

      expect(invalidateQueries).toHaveBeenCalledWith({
        queryKey: getMyFleetsQueryKey(),
      });
    },
  );

  it("leaves them alone on other notifications", () => {
    useNotificationInvalidation().invalidateMyFleets(
      notified("fleet_member_requested"),
    );

    expect(invalidateQueries).not.toHaveBeenCalled();
  });
});

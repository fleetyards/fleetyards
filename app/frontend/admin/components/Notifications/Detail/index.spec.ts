import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  AdminNotificationSeverityEnum,
  AdminNotificationTypeEnum,
  type AdminNotification,
} from "@/services/fyAdminApi";
import Detail from "./index.vue";

const notification = (
  overrides: Partial<AdminNotification> = {},
): AdminNotification => ({
  id: "notification-1",
  notificationType: AdminNotificationTypeEnum.PAINTS_IMPORT,
  severity: AdminNotificationSeverityEnum.ERROR,
  title: "Paints import failed",
  body: "- missing model",
  link: "/admin/imports/",
  occurrences: 2,
  lastOccurredAt: "2026-08-02T00:00:00Z",
  read: true,
  archived: false,
  expiresAt: "2026-09-01T00:00:00Z",
  createdAt: "2026-08-01T00:00:00Z",
  updatedAt: "2026-08-01T00:00:00Z",
  ...overrides,
});

describe("AdminNotificationsDetail", () => {
  it("shows the link, severity, count and when it was last seen", async () => {
    const wrapper = await mountWithDefaults(Detail, {
      props: { notification: notification() },
    });

    expect(wrapper.find(".notification-detail__actions").text()).toContain(
      "Open",
    );
    expect(wrapper.find(".notification-detail__meta").text()).toContain(
      "Error",
    );
    expect(wrapper.find(".notification-detail__count").text()).toBe("×2");

    const facts = wrapper.find(".notification-detail__facts").text();
    expect(facts).toContain("Last seen");
    expect(facts).toContain("Expires");
  });

  it("passes the pane's events through", async () => {
    const wrapper = await mountWithDefaults(Detail, {
      props: { notification: notification() },
    });

    await wrapper
      .find('[data-test="notification-detail-unread"]')
      .trigger("click");

    expect(wrapper.emitted("unread")).toHaveLength(1);
  });
});

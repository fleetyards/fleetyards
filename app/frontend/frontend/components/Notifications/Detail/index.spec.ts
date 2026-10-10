import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { NotificationTypeEnum, type Notification } from "@/services/fyApi";
import Detail from "./index.vue";

window.API_ENDPOINT = "https://api.fleetyards.test/v1";

const notification = (overrides: Partial<Notification> = {}): Notification =>
  ({
    id: "notification-1",
    notificationType: NotificationTypeEnum.FLEET_INVITE,
    title: "You were invited to Blue Sun Logistics",
    read: true,
    archived: false,
    expiresAt: "2026-09-01T00:00:00Z",
    createdAt: "2026-08-01T00:00:00Z",
    updatedAt: "2026-08-01T00:00:00Z",
    link: "/fleets/invites/",
    ...overrides,
  }) as Notification;

describe("NotificationsDetail", () => {
  it("prompts for a selection while nothing is open", async () => {
    const wrapper = await mountWithDefaults(Detail);

    expect(
      wrapper.find('[data-test="notification-detail-empty"]').exists(),
    ).toBe(true);
  });

  it("shows the way on and the date it is archived on", async () => {
    const wrapper = await mountWithDefaults(Detail, {
      props: { notification: notification() },
    });

    expect(
      wrapper.find('[data-test="notification-detail-actions"]').exists(),
    ).toBe(true);
    expect(wrapper.find(".notification-detail__facts").text()).toContain(
      "Moves to the archive",
    );
  });

  it("passes the pane's events through", async () => {
    const wrapper = await mountWithDefaults(Detail, {
      props: { notification: notification() },
    });

    await wrapper
      .find('[data-test="notification-detail-unread"]')
      .trigger("click");
    await wrapper
      .find('[data-test="notification-detail-archive"]')
      .trigger("click");

    expect(wrapper.emitted("unread")).toHaveLength(1);
    expect(wrapper.emitted("archive")).toHaveLength(1);
  });
});

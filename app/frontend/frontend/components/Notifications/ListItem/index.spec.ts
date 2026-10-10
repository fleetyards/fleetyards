import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { NotificationTypeEnum, type Notification } from "@/services/fyApi";
import ListItem from "./index.vue";

window.API_ENDPOINT = "https://api.fleetyards.test/v1";

const notification = (overrides: Partial<Notification> = {}): Notification =>
  ({
    id: "notification-1",
    notificationType: NotificationTypeEnum.FLEET_INVITE,
    title: "You were invited to Blue Sun Logistics",
    read: false,
    archived: false,
    expiresAt: "2026-09-01T00:00:00Z",
    createdAt: "2026-08-01T00:00:00Z",
    updatedAt: "2026-08-01T00:00:00Z",
    link: "/fleets/invites/",
    ...overrides,
  }) as Notification;

describe("NotificationsListItem", () => {
  it("labels the row with the public type and its way on", async () => {
    const wrapper = await mountWithDefaults(ListItem, {
      props: { notification: notification() },
    });

    expect(wrapper.find(".notification-item__meta").text()).toContain(
      "Fleet invite",
    );
    expect(wrapper.find('[data-test="notification-item-open"]').exists()).toBe(
      true,
    );
  });

  it("passes the selection state and the row's events through", async () => {
    const wrapper = await mountWithDefaults(ListItem, {
      props: { notification: notification(), selectable: true, selected: true },
    });

    expect(wrapper.classes()).toContain("notification-item--selected");

    await wrapper.find('[data-test="notification-select"]').trigger("click");
    await wrapper
      .find('[data-test="notification-select"]')
      .trigger("keydown.down");

    expect(wrapper.emitted("select")).toHaveLength(1);
    expect(wrapper.emitted("next")).toHaveLength(1);
  });

  it("offers to move an archived notification back", async () => {
    const wrapper = await mountWithDefaults(ListItem, {
      props: { notification: notification({ archived: true }) },
    });

    expect(wrapper.find('[aria-label="Move back to inbox"]').exists()).toBe(
      true,
    );
  });
});

import { describe, expect, it, vi } from "vitest";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  AdminNotificationSeverityEnum,
  AdminNotificationTypeEnum,
  type AdminNotification,
} from "@/services/fyAdminApi";
import ListItem from "./index.vue";

const notification = (
  overrides: Partial<AdminNotification> = {},
): AdminNotification => ({
  id: "notification-1",
  notificationType: AdminNotificationTypeEnum.PAINTS_IMPORT,
  severity: AdminNotificationSeverityEnum.WARNING,
  title: "Paints import finished with gaps",
  occurrences: 3,
  lastOccurredAt: "2026-08-02T00:00:00Z",
  read: false,
  archived: false,
  expiresAt: "2026-09-01T00:00:00Z",
  createdAt: "2026-08-01T00:00:00Z",
  updatedAt: "2026-08-01T00:00:00Z",
  ...overrides,
});

describe("AdminNotificationsListItem", () => {
  it("labels the row with the admin type, its severity and its count", async () => {
    const wrapper = await mountWithDefaults(ListItem, {
      props: { notification: notification() },
    });

    const meta = wrapper.find(".notification-item__meta").text();
    expect(meta).toContain("Paints Import");
    expect(meta).toContain("Warning");
    expect(wrapper.find(".notification-item__count").text()).toBe("×3");
  });

  it("leaves out the pill for an info notification", async () => {
    const wrapper = await mountWithDefaults(ListItem, {
      props: {
        notification: notification({
          severity: AdminNotificationSeverityEnum.INFO,
          occurrences: 1,
        }),
      },
    });

    expect(wrapper.find(".notification-item__meta").text()).not.toContain(
      "Info",
    );
    expect(wrapper.find(".notification-item__count").exists()).toBe(false);
  });

  it("passes the row's events through", async () => {
    const onToggle = vi.fn();
    const onArchive = vi.fn();
    const wrapper = await mountWithDefaults(ListItem, {
      props: { notification: notification(), selectable: true },
      attrs: { onToggle, onArchive },
    });

    wrapper.findComponent(FormCheckbox).vm.$emit("update:modelValue", true);
    await wrapper.find('[aria-label="Archive"]').trigger("click");

    expect(onToggle).toHaveBeenCalledExactlyOnceWith(true);
    expect(onArchive).toHaveBeenCalledOnce();
  });

  it("moves focus onto the row when the page asks it to", async () => {
    const wrapper = await mountWithDefaults(ListItem, {
      props: { notification: notification() },
      attachTo: document.body,
    });

    (wrapper.vm as unknown as { focus: () => void }).focus();

    expect(document.activeElement).toBe(
      wrapper.find('[data-test="notification-select"]').element,
    );
    wrapper.unmount();
  });
});

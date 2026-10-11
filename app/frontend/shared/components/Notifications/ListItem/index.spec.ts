import { afterEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { SWIPE_THRESHOLD_PX } from "@/shared/composables/useSwipeActions";
import type {
  NotificationEntry,
  NotificationLabels,
} from "@/shared/components/Notifications/types";
import { NOTIFICATION_LABELS } from "@/frontend/components/Notifications/labels";
import ListItem from "./index.vue";

const touch = (type: string, clientX?: number) => {
  const event = new Event(type, { bubbles: true, cancelable: true });

  Object.defineProperty(event, "touches", {
    value: clientX === undefined ? [] : [{ clientX, clientY: 0 }],
  });

  return event;
};

const notification = (
  overrides: Partial<NotificationEntry> = {},
): NotificationEntry => ({
  id: "notification-1",
  title: "Hangar sync finished",
  read: false,
  archived: false,
  createdAt: "2026-08-01T00:00:00Z",
  ...overrides,
});

// The row is a generic SFC, which is not a plain constructor type; this names
// the props the tests use without reaching for `any`.
const RowComponent = ListItem as unknown as new (...args: unknown[]) => {
  $props: {
    notification: NotificationEntry;
    typeLabel: string;
    labels: NotificationLabels;
  };
  $slots: Record<string, unknown>;
};

const mount = (overrides: Partial<NotificationEntry> = {}) =>
  mountWithDefaults<typeof RowComponent>(RowComponent, {
    props: {
      notification: notification(overrides),
      typeLabel: "Hangar sync finished",
      labels: NOTIFICATION_LABELS,
    },
  });

type Mounted = Awaited<ReturnType<typeof mount>>;

const swipe = async (wrapper: Mounted, dx: number, release = true) => {
  const row = wrapper.find(".notification-item").element;

  row.dispatchEvent(touch("touchstart", 200));
  row.dispatchEvent(touch("touchmove", 200 + dx));
  await flushPromises();

  if (release) {
    row.dispatchEvent(touch("touchend"));
    await flushPromises();
  }
};

afterEach(() => {
  vi.useRealTimers();
});

describe("SharedNotificationsListItem", () => {
  it("marks an unread row read on a swipe right, and a read one unread", async () => {
    const unread = await mount();
    await swipe(unread, SWIPE_THRESHOLD_PX + 20);

    const read = await mount({ read: true });
    await swipe(read, SWIPE_THRESHOLD_PX + 20);

    expect(unread.emitted("read")).toHaveLength(1);
    expect(read.emitted("unread")).toHaveLength(1);
  });

  it("archives on a swipe left, and moves an archived row back", async () => {
    const inbox = await mount();
    await swipe(inbox, -(SWIPE_THRESHOLD_PX + 20));

    const archived = await mount({ archived: true });
    await swipe(archived, -(SWIPE_THRESHOLD_PX + 20));

    expect(inbox.emitted("archive")).toHaveLength(1);
    expect(archived.emitted("unarchive")).toHaveLength(1);
  });

  it("names what letting go will do while the row is dragged", async () => {
    const wrapper = await mount();

    await swipe(wrapper, SWIPE_THRESHOLD_PX + 20, false);

    const backdrop = wrapper.find('[data-test="notification-swipe-backdrop"]');
    expect(backdrop.text()).toBe("Mark as read");
    expect(wrapper.find(".notification-row--armed").exists()).toBe(true);
  });

  it("clears the backdrop once the row has eased back", async () => {
    vi.useFakeTimers();

    const wrapper = await mount();
    const backdrop = '[data-test="notification-swipe-backdrop"]';

    await swipe(wrapper, SWIPE_THRESHOLD_PX - 20);

    expect(wrapper.find(backdrop).exists()).toBe(true);

    vi.advanceTimersByTime(300);
    await flushPromises();

    expect(wrapper.find(backdrop).exists()).toBe(false);
  });

  it("keeps the uncovered width while the row eases back", async () => {
    const wrapper = await mount();

    await swipe(wrapper, SWIPE_THRESHOLD_PX - 20);

    expect(
      (
        wrapper.find(".notification-row").element as HTMLElement
      ).style.getPropertyValue("--swipe-reveal"),
    ).toBe(`${SWIPE_THRESHOLD_PX - 20}px`);
  });

  it("keeps the row's buttons for a reader that does not swipe", async () => {
    const wrapper = await mount();

    expect(wrapper.find('[aria-label="Archive"]').exists()).toBe(true);
    expect(wrapper.find('[aria-label="Delete"]').exists()).toBe(true);
  });
});

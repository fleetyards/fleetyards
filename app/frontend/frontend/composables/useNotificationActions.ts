import {
  NotificationRecordTypeEnum,
  type Notification,
  type NotificationTypeEnum,
} from "@/services/fyApi";

export type NotificationLink = {
  key: string;
  icon: string;
  to?: string;
  href?: string;
  primary?: boolean;
};

/*
 * What a notification's link actually leads to. Every type used to wear the
 * same "Open", so a fleet invite and a ship added to the hangar were told apart
 * only by the title above the button.
 *
 * Typed against the full enum on purpose: a new notification type then fails
 * the build here rather than quietly falling back to "Open" in production.
 */
const PRIMARY_ACTIONS: Record<`${NotificationTypeEnum}`, string> = {
  hangar_create: "openHangar",
  hangar_destroy: "openHangar",
  wishlist_create: "openWishlist",
  wishlist_destroy: "openWishlist",
  model_on_sale: "openModel",
  new_model: "openModel",
  hangar_sync_finished: "openHangar",
  hangar_sync_failed: "openHangar",
  fleet_invite: "openInvite",
  fleet_member_requested: "reviewRequest",
  fleet_member_accepted: "openMembers",
  fleet_request_accepted: "openFleet",
  fleet_inventory_item_added: "openInventory",
  fleet_event_published: "openEvent",
  fleet_event_locked: "openEvent",
  fleet_event_starting_soon: "openEvent",
  fleet_event_started: "openEvent",
  fleet_event_completed: "openEvent",
  fleet_event_cancelled: "openEvent",
  fleet_event_signup_added: "openRoster",
  fleet_event_signup_withdrawn: "openRoster",
  fleet_event_signup_confirmed: "openEvent",
  fleet_event_signup_assigned: "openEvent",
  fleet_event_signup_kicked: "openEvent",
};

const ACTION_ICONS: Record<string, string> = {
  openHangar: "fa-duotone fa-warehouse",
  openWishlist: "fa-duotone fa-heart",
  openModel: "fa-duotone fa-starship",
  openInvite: "fa-duotone fa-envelope-open",
  reviewRequest: "fa-duotone fa-user-check",
  openMembers: "fa-duotone fa-users",
  openFleet: "fa-duotone fa-shield",
  openInventory: "fa-duotone fa-boxes-stacked",
  openEvent: "fa-duotone fa-calendar-day",
  openRoster: "fa-duotone fa-list-check",
  addToCalendar: "fa-duotone fa-calendar-plus",
  open: "fa-duotone fa-arrow-up-right-from-square",
};

// Where the shortcut to the fleet would either repeat the primary target or
// send the reader somewhere they cannot go yet - an invite is answered before
// its fleet is readable.
const NO_FLEET_SHORTCUT = ["openFleet", "openInvite"];

const icon = (key: string) => ACTION_ICONS[key] || ACTION_ICONS.open;

// The keys are camelCase because they are translation keys; the test ids the
// rest of the app hands out are kebab-case.
export const actionTestId = (key: string) =>
  `notification-action-${key.replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase()}`;

export const useNotificationActions = () => {
  const primaryLink = (
    notification: Notification,
  ): NotificationLink | undefined => {
    if (!notification.link) {
      return undefined;
    }

    const key = PRIMARY_ACTIONS[notification.notificationType] || "open";

    return { key, icon: icon(key), to: notification.link, primary: true };
  };

  /*
   * The side doors: the calendar file an event already serves, and the fleet
   * behind whatever the notification is about. Both come off the record
   * reference the payload carries, so neither costs a request.
   */
  const secondaryLinks = (notification: Notification): NotificationLink[] => {
    const record = notification.record;

    if (!record) {
      return [];
    }

    const links: NotificationLink[] = [];

    if (
      record.type === NotificationRecordTypeEnum.FLEET_EVENT &&
      record.fleetSlug &&
      record.eventSlug
    ) {
      links.push({
        key: "addToCalendar",
        icon: icon("addToCalendar"),
        href: `${window.API_ENDPOINT}/fleets/${record.fleetSlug}/events/${record.eventSlug}/event.ics`,
      });
    }

    const primaryKey = PRIMARY_ACTIONS[notification.notificationType];

    if (record.fleetSlug && !NO_FLEET_SHORTCUT.includes(primaryKey)) {
      links.push({
        key: "openFleet",
        icon: icon("openFleet"),
        to: `/fleets/${record.fleetSlug}`,
      });
    }

    return links;
  };

  const linksFor = (notification: Notification): NotificationLink[] => {
    const primary = primaryLink(notification);

    return [...(primary ? [primary] : []), ...secondaryLinks(notification)];
  };

  return { primaryLink, secondaryLinks, linksFor };
};

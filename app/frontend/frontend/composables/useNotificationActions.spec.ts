import { describe, expect, it } from "vitest";

import { useNotificationActions } from "./useNotificationActions";
import {
  NotificationRecordTypeEnum,
  NotificationTypeEnum,
  type Notification,
  type NotificationRecord,
  type NotificationTypeEnum as NotificationType,
} from "@/services/fyApi";

window.API_ENDPOINT = "https://api.fleetyards.test/v1";

const notification = (
  notificationType: `${NotificationType}`,
  attributes: { link?: string; record?: NotificationRecord } = {},
): Notification =>
  ({
    id: "notification-1",
    notificationType,
    title: "A notification",
    read: false,
    archived: false,
    expiresAt: "2026-09-01T00:00:00Z",
    createdAt: "2026-08-01T00:00:00Z",
    updatedAt: "2026-08-01T00:00:00Z",
    ...attributes,
  }) as Notification;

const keysFor = (input: Notification) =>
  useNotificationActions()
    .linksFor(input)
    .map((link) => link.key);

describe("useNotificationActions", () => {
  it("names the target rather than saying 'open'", () => {
    expect(
      keysFor(notification(NotificationTypeEnum.FLEET_INVITE, { link: "/x" })),
    ).toEqual(["openInvite"]);

    expect(
      keysFor(notification(NotificationTypeEnum.HANGAR_CREATE, { link: "/x" })),
    ).toEqual(["openHangar"]);

    expect(
      keysFor(
        notification(NotificationTypeEnum.FLEET_MEMBER_REQUESTED, {
          link: "/x",
        }),
      ),
    ).toEqual(["reviewRequest"]);
  });

  it("offers nothing when the notification carries no link", () => {
    expect(keysFor(notification(NotificationTypeEnum.HANGAR_CREATE))).toEqual(
      [],
    );
  });

  it("adds the calendar file for an event, off the reference alone", () => {
    const links = useNotificationActions().linksFor(
      notification(NotificationTypeEnum.FLEET_EVENT_PUBLISHED, {
        link: "/fleets/test-fleet/events/mining-run",
        record: {
          type: NotificationRecordTypeEnum.FLEET_EVENT,
          id: "event-1",
          fleetSlug: "test-fleet",
          eventSlug: "mining-run",
        },
      }),
    );

    expect(links.map((link) => link.key)).toEqual([
      "openEvent",
      "addToCalendar",
      "openFleet",
    ]);

    expect(links[1].href).toBe(
      "https://api.fleetyards.test/v1/fleets/test-fleet/events/mining-run/event.ics",
    );
  });

  it("does not send an invited user to a fleet they are not in yet", () => {
    expect(
      keysFor(
        notification(NotificationTypeEnum.FLEET_INVITE, {
          link: "/fleets/invites",
          record: {
            type: NotificationRecordTypeEnum.FLEET_MEMBERSHIP,
            id: "membership-1",
            fleetSlug: "test-fleet",
            username: "someone",
          },
        }),
      ),
    ).toEqual(["openInvite"]);
  });

  it("does not repeat the fleet when the fleet is already the target", () => {
    expect(
      keysFor(
        notification(NotificationTypeEnum.FLEET_REQUEST_ACCEPTED, {
          link: "/fleets/test-fleet",
          record: {
            type: NotificationRecordTypeEnum.FLEET_MEMBERSHIP,
            id: "membership-1",
            fleetSlug: "test-fleet",
            username: "someone",
          },
        }),
      ),
    ).toEqual(["openFleet"]);
  });
});

import { describe, expect, it } from "vitest";
import { buildCalendarEvent } from "./calendarEvent";
import {
  type FleetEvent,
  MissionCategoryEnum,
  FleetEventSignupApprovalEnum,
  FleetEventStatusEnum,
  FleetEventVisibilityEnum,
} from "@/services/fyApi";

const NOW = "2026-11-04T12:00:00Z";

const event = (overrides: Partial<FleetEvent> = {}): FleetEvent => ({
  id: "event-1",
  fleetId: "fleet-1",
  title: "Jumptown Convoy Escort",
  slug: "jumptown",
  status: FleetEventStatusEnum.OPEN,
  startsAt: "2026-11-04T20:00:00Z",
  timezone: "UTC",
  visibility: FleetEventVisibilityEnum.FLEET,
  category: MissionCategoryEnum.CARGO_HAULING,
  autoLockEnabled: true,
  signupApproval: FleetEventSignupApprovalEnum.DIRECT,
  archived: false,
  externalUid: "uid-1",
  signupsCount: 0,
  teamCount: 0,
  past: false,
  signupsOpen: true,
  discordConfigured: false,
  createdAt: NOW,
  updatedAt: NOW,
  ...overrides,
});

describe("buildCalendarEvent", () => {
  // The library leaves an ISO string set after mount at its UTC clock; only a
  // Date reaches the reader's zone.
  it("hands the library instants, not ISO strings", () => {
    const result = buildCalendarEvent(
      event({ endsAt: "2026-11-04T22:30:00+02:00" }),
    );

    expect(result.start).toBeInstanceOf(Date);
    expect(result.end).toBeInstanceOf(Date);
    expect(result.start.toISOString()).toBe("2026-11-04T20:00:00.000Z");
    expect(result.end.toISOString()).toBe("2026-11-04T20:30:00.000Z");
  });

  it("ends an event without an end an hour after it starts", () => {
    const result = buildCalendarEvent(event({ endsAt: undefined }));

    expect(result.end.toISOString()).toBe("2026-11-04T21:00:00.000Z");
  });
});

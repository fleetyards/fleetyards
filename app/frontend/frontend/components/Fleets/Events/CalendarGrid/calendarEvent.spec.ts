import { describe, expect, it } from "vitest";
import { buildCalendarEvent, buildGameCalendarEvent } from "./calendarEvent";
import {
  type FleetEvent,
  type GameEvent,
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

describe("buildGameCalendarEvent", () => {
  const gameEvent: GameEvent = {
    id: "xeno",
    title: "XenoThreat",
    category: MissionCategoryEnum.SHIP_COMBAT,
    startsAt: "2026-11-15T00:00:00Z",
    createdAt: NOW,
    updatedAt: NOW,
  };

  it("keeps game events apart from fleet events of the same id", () => {
    expect(buildGameCalendarEvent(gameEvent).id).toBe("game-xeno");
  });

  it("carries the game event for the chip and the click", () => {
    expect(buildGameCalendarEvent(gameEvent).extendedProps.gameEvent).toBe(
      gameEvent,
    );
  });

  it("gives an event without an end an hour", () => {
    expect(buildGameCalendarEvent(gameEvent).end.toISOString()).toBe(
      "2026-11-15T01:00:00.000Z",
    );
  });
});

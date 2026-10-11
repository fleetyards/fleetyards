import { describe, expect, it } from "vitest";
import type { FleetMemberHealth } from "@/services/fyApi";
import { byUrgency, memberHealthChecks, needsAttention } from "./memberHealth";

const none = { totalCount: 0, items: [] };

const healthWith = (
  overrides: Partial<FleetMemberHealth> = {},
): FleetMemberHealth => ({
  inactiveDays: 30,
  fleetRsiVerified: true,
  rsiMemberCount: null,
  memberCount: 10,
  hiddenShipsCount: 0,
  admins: { totalCount: 2, items: [], candidates: [] },
  emptyRoles: null,
  unverifiedMembers: null,
  membersWithoutRsiHandle: none,
  inactiveMembers: none,
  waitingJoinRequests: none,
  unansweredInvitations: none,
  staleInviteUrls: null,
  membersWithoutDiscord: null,
  membersWithoutSquadron: null,
  emptySquadrons: null,
  ...overrides,
});

const byKey = (health: FleetMemberHealth) =>
  Object.fromEntries(
    memberHealthChecks(health).map((check) => [check.key, check]),
  );

describe("memberHealthChecks", () => {
  it("leaves out the checks the answer says do not apply", () => {
    expect(Object.keys(byKey(healthWith()))).toEqual([
      "admins",
      "noHandle",
      "inactive",
      "joinRequests",
      "invitations",
      "hiddenShips",
    ]);
  });

  it("flags no admin at all as critical too", () => {
    expect(
      byKey(
        healthWith({ admins: { totalCount: 0, items: [], candidates: [] } }),
      ).admins.tone,
    ).toBe("critical");
  });

  it("flags a single admin as critical and shows how many there are", () => {
    expect(
      byKey(
        healthWith({ admins: { totalCount: 1, items: [], candidates: [] } }),
      ).admins,
    ).toMatchObject({ tone: "critical", count: 1, display: 1 });
    expect(byKey(healthWith()).admins).toMatchObject({
      tone: "ok",
      count: 0,
      display: 2,
    });
  });

  it("ranks verification above activity", () => {
    const keys = memberHealthChecks(
      healthWith({ unverifiedMembers: none, membersWithoutRsiHandle: null }),
    ).map((check) => check.key);

    expect(keys.indexOf("unverified")).toBeLessThan(keys.indexOf("inactive"));
  });

  it("does not count hidden hangars as something to do", () => {
    const hidden = byKey(healthWith({ hiddenShipsCount: 3 })).hiddenShips;

    expect(hidden.tone).toBe("info");
    expect(needsAttention(hidden)).toBe(false);
  });

  it("sorts the worst first, keeping page order within a tone", () => {
    const sorted = byUrgency(
      memberHealthChecks(
        healthWith({
          admins: { totalCount: 1, items: [], candidates: [] },
          inactiveMembers: { totalCount: 2, items: [] },
          waitingJoinRequests: { totalCount: 1, items: [] },
          hiddenShipsCount: 1,
        }),
      ),
    ).map((check) => check.key);

    expect(sorted.slice(0, 4)).toEqual([
      "admins",
      "inactive",
      "joinRequests",
      "hiddenShips",
    ]);
  });
});

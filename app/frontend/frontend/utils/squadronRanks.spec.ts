import { describe, expect, it } from "vitest";
import { outranks, rankOptionsFor } from "./squadronRanks";

const leader = { key: "leader", position: 0 };
const coLeader = { key: "co_leader", position: 1 };
const officer = { key: "officer", position: 2 };
const member = { key: "member", position: 3 };
const ranks = [leader, coLeader, officer, member];

const keys = (list: { key: string }[]) => list.map((rank) => rank.key);

describe("outranks", () => {
  it("lets a fleet-wide manager act on anyone", () => {
    expect(outranks({ fleetWide: true, canManageRanks: true }, leader)).toBe(
      true,
    );
  });

  it("lets a squadron rank act only below itself", () => {
    const viewer = {
      fleetWide: false,
      canManageRanks: false,
      viewerRole: officer,
    };

    expect(outranks(viewer, member)).toBe(true);
    expect(outranks(viewer, officer)).toBe(false);
    expect(outranks(viewer, leader)).toBe(false);
  });

  it("refuses a viewer who holds no rank in the squadron", () => {
    expect(outranks({ fleetWide: false, canManageRanks: false }, member)).toBe(
      false,
    );
  });
});

describe("rankOptionsFor", () => {
  it("offers every rank to a fleet-wide manager", () => {
    const viewer = { fleetWide: true, canManageRanks: true };

    expect(
      keys(rankOptionsFor(viewer, ranks, { rank: member, isSelf: false })),
    ).toEqual(keys(ranks));
  });

  it("offers a Leader the ranks below their own, never another Leader", () => {
    const viewer = {
      fleetWide: false,
      canManageRanks: true,
      viewerRole: leader,
    };

    expect(
      keys(rankOptionsFor(viewer, ranks, { rank: member, isSelf: false })),
    ).toEqual(["co_leader", "officer", "member"]);
  });

  it("offers nothing for a member the viewer does not outrank", () => {
    const viewer = {
      fleetWide: false,
      canManageRanks: true,
      viewerRole: coLeader,
    };

    expect(
      rankOptionsFor(viewer, ranks, { rank: leader, isSelf: false }),
    ).toEqual([]);
  });

  it("offers an Officer nothing for somebody else", () => {
    const viewer = {
      fleetWide: false,
      canManageRanks: false,
      viewerRole: officer,
    };

    expect(
      rankOptionsFor(viewer, ranks, { rank: member, isSelf: false }),
    ).toEqual([]);
  });

  it("lets anyone step down, never up", () => {
    const viewer = {
      fleetWide: false,
      canManageRanks: false,
      viewerRole: officer,
    };

    expect(
      keys(rankOptionsFor(viewer, ranks, { rank: officer, isSelf: true })),
    ).toEqual(["officer", "member"]);
  });
});

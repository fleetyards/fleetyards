import type { FleetMemberHealth } from "@/services/fyApi";

export type MemberHealthCheckKey =
  | "admins"
  | "emptyRoles"
  | "unverified"
  | "noHandle"
  | "inactive"
  | "joinRequests"
  | "invitations"
  | "inviteUrls"
  | "discord"
  | "emptySquadrons"
  | "noSquadron"
  | "hiddenShips";

export type MemberHealthGroup =
  "leadership" | "rsi" | "activity" | "requests" | "integrations";

export type MemberHealthTone = "critical" | "attention" | "info" | "ok";

export type MemberHealthCheck = {
  key: MemberHealthCheckKey;
  group: MemberHealthGroup;
  tone: MemberHealthTone;
  // How many things are wrong; zero is a clear check.
  count: number;
  // What the overview and the badge show, where that is not the count.
  display: number;
};

export const MEMBER_HEALTH_GROUPS: MemberHealthGroup[] = [
  "leadership",
  "rsi",
  "activity",
  "requests",
  "integrations",
];

type Definition = {
  key: MemberHealthCheckKey;
  group: MemberHealthGroup;
  tone: Exclude<MemberHealthTone, "ok">;
  // Null when the check does not apply to the fleet or the reader.
  count: (health: FleetMemberHealth) => number | null;
  display?: (health: FleetMemberHealth) => number;
};

// In page order: verification ranks above activity, and an empty squadron
// above a member without one.
const DEFINITIONS: Definition[] = [
  {
    key: "admins",
    group: "leadership",
    tone: "critical",
    // None at all is worse than one, not fine.
    count: (health) => (health.admins.totalCount <= 1 ? 1 : 0),
    // The check is about having one; the number shown is how many there are.
    display: (health) => health.admins.totalCount,
  },
  {
    key: "emptyRoles",
    group: "leadership",
    tone: "attention",
    count: (health) => health.emptyRoles?.length ?? null,
  },
  {
    key: "unverified",
    group: "rsi",
    tone: "attention",
    count: (health) => health.unverifiedMembers?.totalCount ?? null,
  },
  {
    key: "noHandle",
    group: "rsi",
    tone: "attention",
    count: (health) => health.membersWithoutRsiHandle?.totalCount ?? null,
  },
  {
    key: "inactive",
    group: "activity",
    tone: "attention",
    count: (health) => health.inactiveMembers.totalCount,
  },
  {
    key: "joinRequests",
    group: "requests",
    tone: "attention",
    count: (health) => health.waitingJoinRequests.totalCount,
  },
  {
    key: "invitations",
    group: "requests",
    tone: "attention",
    count: (health) => health.unansweredInvitations.totalCount,
  },
  {
    key: "inviteUrls",
    group: "requests",
    tone: "attention",
    count: (health) => health.staleInviteUrls?.totalCount ?? null,
  },
  {
    key: "discord",
    group: "integrations",
    tone: "attention",
    count: (health) => health.membersWithoutDiscord?.totalCount ?? null,
  },
  {
    key: "emptySquadrons",
    group: "integrations",
    tone: "attention",
    count: (health) => health.emptySquadrons?.totalCount ?? null,
  },
  {
    key: "noSquadron",
    group: "integrations",
    tone: "attention",
    count: (health) => health.membersWithoutSquadron?.totalCount ?? null,
  },
  {
    key: "hiddenShips",
    group: "integrations",
    tone: "info",
    count: (health) => health.hiddenShipsCount,
  },
];

export const memberHealthChecks = (
  health: FleetMemberHealth,
): MemberHealthCheck[] =>
  DEFINITIONS.flatMap((definition) => {
    const count = definition.count(health);
    if (count === null) return [];

    return [
      {
        key: definition.key,
        group: definition.group,
        tone: count > 0 ? definition.tone : "ok",
        count,
        display: definition.display?.(health) ?? count,
      },
    ];
  });

const TONE_RANK: Record<MemberHealthTone, number> = {
  critical: 0,
  attention: 1,
  info: 2,
  ok: 3,
};

// Worst first, page order within a tone.
export const byUrgency = (checks: MemberHealthCheck[]) =>
  [...checks].sort((a, b) => TONE_RANK[a.tone] - TONE_RANK[b.tone]);

// Info is something to know, not something to do.
export const needsAttention = (check: MemberHealthCheck) =>
  check.tone === "critical" || check.tone === "attention";

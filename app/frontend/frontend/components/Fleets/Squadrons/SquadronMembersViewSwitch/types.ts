export const SQUADRON_MEMBERS_VIEWS = ["members", "requests"] as const;

export type SquadronMembersView = (typeof SQUADRON_MEMBERS_VIEWS)[number];

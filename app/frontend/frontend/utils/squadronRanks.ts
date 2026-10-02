import type { FleetSquadronRole } from "@/services/fyApi";

type Rank = Pick<FleetSquadronRole, "position">;

export type SquadronRankViewer = {
  // A fleet role that manages every squadron's members.
  fleetWide: boolean;
  // The viewer's own rank in this squadron, if they hold one.
  viewerRole?: Rank;
  canManageRanks: boolean;
};

/*
 * The server's rule, mirrored so a roster row only offers what the update
 * will accept: a fleet-wide privilege covers everyone, a squadron rank only
 * the people ranked below it.
 */
export const outranks = (viewer: SquadronRankViewer, rank?: Rank) => {
  if (viewer.fleetWide) return true;
  if (!viewer.viewerRole || !rank) return false;

  return rank.position > viewer.viewerRole.position;
};

export const rankOptionsFor = <T extends Rank>(
  viewer: SquadronRankViewer,
  ranks: T[],
  target: { rank?: Rank; isSelf: boolean },
): T[] => {
  if (viewer.fleetWide) return ranks;

  const own = viewer.viewerRole;
  if (!own) return [];

  // Stepping down is always one's own to do.
  if (target.isSelf)
    return ranks.filter((rank) => rank.position >= own.position);

  if (!viewer.canManageRanks || !outranks(viewer, target.rank)) return [];

  return ranks.filter((rank) => rank.position > own.position);
};

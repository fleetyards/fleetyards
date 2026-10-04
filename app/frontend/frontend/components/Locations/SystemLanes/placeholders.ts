import type { JumpConnection } from "./layout";
import type { LocationJumpPoint } from "@/services/fyApi";

// Systems CIG has shown but the game files do not have yet, drawn so the jump
// points that already lead to them have somewhere to go. Each one steps aside
// on its own once a listed system carries its name.
//
// The colours are read off CIG's system overviews, the star's from its
// spectral class where the lore gives one; nothing here comes from the game.
export interface PlaceholderBody {
  name: string;
  color: string;
  // A surface the globe knows: "cratered", "gas_giant", … Rocky when unset.
  bodyType?: string;
}

export interface PlaceholderSystem {
  id: string;
  name: string;
  star: PlaceholderBody;
  // In orbit order, as CIG's system overviews show them.
  planets: PlaceholderBody[];
  // Announced connections the game files have no jump point for yet, by the
  // name a jump point would give the system at the other end.
  jumpsTo: string[];
}

export const PLACEHOLDER_SYSTEMS: PlaceholderSystem[] = [
  {
    id: "placeholder-castra",
    name: "Castra System",
    star: { name: "Castra", color: "#ffb066" },
    planets: [
      { name: "Castra", color: "#a89a45" },
      { name: "Cascom", color: "#9a5e5a" },
    ],
    jumpsTo: ["Nyx", "Pyro", "Terra"],
  },
  {
    id: "placeholder-terra",
    name: "Terra System",
    star: { name: "Terra", color: "#ffe08a" },
    planets: [
      { name: "Aero", color: "#a5583a" },
      { name: "Gen", color: "#4f88a8" },
      { name: "Terra", color: "#6f8a6a" },
      { name: "Pike", color: "#85878c", bodyType: "cratered" },
    ],
    jumpsTo: [],
  },
];

// The name a jump point gives its destination: "Terra" for the Terra System.
export const placeholderDestination = (placeholder: PlaceholderSystem) =>
  placeholder.star.name.toLowerCase();

// A jump point into a placeholder names it but has no id to point at.
export const pointIntoPlaceholders = (
  jumpPoints: LocationJumpPoint[],
  placeholders: PlaceholderSystem[],
): LocationJumpPoint[] => {
  const placeholderIds = new Map(
    placeholders.map((placeholder) => [
      placeholderDestination(placeholder),
      placeholder.id,
    ]),
  );

  return jumpPoints.map((jumpPoint) =>
    jumpPoint.destinationSystemId
      ? jumpPoint
      : {
          ...jumpPoint,
          destinationSystemId:
            placeholderIds.get(jumpPoint.destinationName.toLowerCase()) ?? null,
        },
  );
};

// The announced connections, between whatever stands for each end on the
// page: the system once it is listed, its placeholder until then. Looked up
// by the name jump points use, lower case.
export const plannedConnections = (
  idsByName: Map<string, string>,
): JumpConnection[] =>
  PLACEHOLDER_SYSTEMS.flatMap((placeholder) =>
    placeholder.jumpsTo.flatMap((name) => {
      const ownId = idsByName.get(placeholderDestination(placeholder));
      const otherId = idsByName.get(name.toLowerCase());

      if (!ownId || !otherId) {
        return [];
      }

      const pair = [ownId, otherId].sort() as [string, string];

      return [
        { key: pair.join(":"), systemIds: pair, ends: {}, planned: true },
      ];
    }),
  );

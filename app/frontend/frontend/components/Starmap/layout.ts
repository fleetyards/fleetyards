import type { StarmapSurface } from "./bodies";
import {
  LocationKindEnum,
  NullableLocationBodyTypeEnum,
  type Location,
  type LocationJumpPoint,
  type LocationStarmapPlace,
} from "@/services/fyApi";

export type StarmapRole = "system" | "star" | "planet" | "moon" | "place";

export type StarmapVector = [number, number, number];

/**
 * One thing the map draws, in scene units from the centre of its world: the
 * star for a system, the middle of the ring for the systems.
 */
export interface StarmapItem {
  key: string;
  name: string;
  slug: string;
  kind: LocationKindEnum;
  role: StarmapRole;
  position: StarmapVector;
  // Null where the game gives no size: everything but stars, planets and moons.
  radius: number | null;
  color: string;
  // How a planet or moon is painted; null for everything else.
  surface: StarmapSurface | null;
  // The surface the game's own starmap wraps the body in, where the export
  // has one. The painted surface stands in while it loads, or without it.
  texture: string | null;
  // A flare star, as Pyro is.
  unstable: boolean;
  // Whether it is named on the map where there is room. Every item is named
  // while the pointer is on it, whatever this says.
  labelled: boolean;
  // Which label gives way where two would overlap: the lower keeps its own.
  rank: number;
  // The body it belongs to: a moon's planet, a planet's star, the planet an
  // outpost stands on. What it is seen with, and what Escape steps out to.
  anchor: string | null;
  // How far it is from its anchor, in metres.
  distance: number | null;
  realRadius: number | null;
  parentName: string | null;
}

export interface StarmapLink {
  from: StarmapVector;
  to: StarmapVector;
  temporary: boolean;
}

export interface StarmapOrbit {
  // The item the orbit is centred on, and the item that runs on it.
  center: string;
  body: string;
  radius: number;
}

export interface StarmapScene {
  kind: "systems" | "system";
  items: StarmapItem[];
  orbits: StarmapOrbit[];
  links: StarmapLink[];
  // How far out the whole world reaches, for the overview.
  extent: number;
}

// Metres per scene unit. A system is tens of gigametres across, an outpost a
// few hundred metres off its planet's surface; one unit per megametre keeps
// both within what the floating origin and a logarithmic depth buffer resolve.
export const UNIT = 1e6;

const SYSTEMS_RING = 20;

const COLORS: Record<StarmapRole, string> = {
  system: "#428bca",
  star: "#ffd27a",
  planet: "#8fb3d9",
  moon: "#9aa4b1",
  place: "#5aafd4",
};

const LABELLED_PLACES = new Set<LocationKindEnum>([
  LocationKindEnum.CITY,
  LocationKindEnum.SPACEPORT,
  LocationKindEnum.STATION,
  LocationKindEnum.JUMP_POINT,
]);

const BODY_KINDS = new Set<LocationKindEnum>([
  LocationKindEnum.STAR,
  LocationKindEnum.PLANET,
  LocationKindEnum.MOON,
]);

// A clinic inside a station or a venue in a city is the same point at any
// zoom the map has: drawn apart, a click on the station would as likely land
// on its clinic. They are folded into the place they are in, whose page lists
// them.
const INSIDE_METRES = 20_000;

// The game is z-up with its planets in the xy plane; three.js is y-up.
export const toScene = (
  position: number[],
  origin: number[],
  unit: number,
): StarmapVector => [
  (position[0] - origin[0]) / unit,
  (position[2] - origin[2]) / unit,
  (origin[1] - position[1]) / unit,
];

const length = (vector: number[]) => Math.hypot(...vector);

const gap = (a: number[], b: number[]) =>
  length(a.map((value, index) => value - b[index]));

const planarDistance = (position: number[], origin: number[]) =>
  Math.hypot(position[0] - origin[0], position[1] - origin[1]);

const roleOf = (place: LocationStarmapPlace): StarmapRole => {
  if (place.kind === LocationKindEnum.STAR) return "star";
  if (place.kind === LocationKindEnum.PLANET) return "planet";
  if (place.kind === LocationKindEnum.MOON) return "moon";
  return "place";
};

const RANKS: Record<StarmapRole, number> = {
  system: 0,
  star: 0,
  planet: 1,
  moon: 2,
  place: 3,
};

const rankOf = (place: LocationStarmapPlace, role: StarmapRole) => {
  if (role !== "place") return RANKS[role];

  return LABELLED_PLACES.has(place.kind) || place.gateway ? 3 : 4;
};

// As the location pages paint a body: an ordinary moon is cratered like an
// asteroid, an ordinary planet has continents.
const surfaceOf = (
  place: LocationStarmapPlace,
  role: StarmapRole,
): StarmapSurface | null => {
  if (role !== "planet" && role !== "moon") return null;

  switch (place.bodyType) {
    case NullableLocationBodyTypeEnum.GAS_GIANT:
      return "gas";
    case NullableLocationBodyTypeEnum.ICE_GIANT:
      return "ice";
    case NullableLocationBodyTypeEnum.CITY:
      return "city";
    case NullableLocationBodyTypeEnum.ASTEROID:
      return "cratered";
    default:
      return role === "moon" ? "cratered" : "rocky";
  }
};

// Where a place belongs, walked up its parents: the body it is on or around,
// whether it sits at a Lagrange point, which the game draws with the star, and
// whether it is inside another place.
const ancestry = (places: LocationStarmapPlace[]) => {
  const byId = new Map(places.map((place) => [place.id, place]));
  const parentOf = (place: LocationStarmapPlace) =>
    place.parentId ? byId.get(place.parentId) : undefined;

  const bodyOf = (place: LocationStarmapPlace) => {
    let parent = parentOf(place);

    while (parent && !BODY_KINDS.has(parent.kind)) {
      parent = parentOf(parent);
    }

    return parent;
  };

  const atLagrangePoint = (place: LocationStarmapPlace) => {
    let current: LocationStarmapPlace | undefined = place;

    while (current && !BODY_KINDS.has(current.kind)) {
      if (current.lagrangePoint) return true;
      current = parentOf(current);
    }

    return false;
  };

  const inside = (place: LocationStarmapPlace) => {
    const parent = parentOf(place);
    if (!parent || BODY_KINDS.has(parent.kind) || parent.lagrangePoint) {
      return false;
    }

    return gap(place.position, parent.position) < INSIDE_METRES;
  };

  return { bodyOf, atLagrangePoint, inside };
};

/**
 * Every listed system on a ring, joined by its jump tunnels. The game files
 * place no system relative to another, so the ring says nothing about
 * distance.
 */
export const systemsScene = (
  systems: Location[],
  jumpPoints: LocationJumpPoint[],
): StarmapScene => {
  const sorted = [...systems].sort((a, b) =>
    (a.name ?? a.slug).localeCompare(b.name ?? b.slug),
  );

  const positions = new Map<string, StarmapVector>();

  const items = sorted.map((system, index): StarmapItem => {
    const angle = (index / sorted.length) * Math.PI * 2 - Math.PI / 2;
    const position: StarmapVector =
      sorted.length === 1
        ? [0, 0, 0]
        : [Math.cos(angle) * SYSTEMS_RING, 0, Math.sin(angle) * SYSTEMS_RING];

    positions.set(system.id, position);

    return {
      key: system.id,
      name: system.name ?? system.slug,
      slug: system.slug,
      kind: system.kind,
      role: "system",
      position,
      radius: null,
      color: COLORS.system,
      surface: null,
      texture: null,
      unstable: false,
      labelled: true,
      rank: 0,
      anchor: null,
      distance: null,
      realRadius: null,
      parentName: null,
    };
  });

  // One line per pair of systems, whichever end lists the tunnel. It is only
  // drawn as temporary while every tunnel between the two is.
  const pairs = new Map<string, StarmapLink>();

  for (const point of jumpPoints) {
    if (!point.destinationSystemId) continue;

    const from = positions.get(point.systemId);
    const to = positions.get(point.destinationSystemId);
    if (!from || !to) continue;

    const pair = [point.systemId, point.destinationSystemId].sort().join(":");
    const known = pairs.get(pair);

    if (known) {
      known.temporary = known.temporary && point.temporary;
    } else {
      pairs.set(pair, { from, to, temporary: point.temporary });
    }
  }

  return {
    kind: "systems",
    items,
    orbits: [],
    links: [...pairs.values()],
    extent: SYSTEMS_RING * 1.8,
  };
};

/**
 * A whole system as one world, at the positions the game gives it: the star,
 * its planets and their moons on their orbits, and every place around them.
 * What is near a body is only shown as the camera comes near it; the scene
 * decides that as it moves.
 */
export const systemScene = (places: LocationStarmapPlace[]): StarmapScene => {
  const star = places.find((place) => place.kind === LocationKindEnum.STAR);
  const origin = star?.position ?? [0, 0, 0];
  const { bodyOf, atLagrangePoint, inside } = ancestry(places);

  const shown = places.filter((place) => place === star || !inside(place));

  // A Lagrange point with a station at it is named by the station: "HUR-L1
  // Green Glade Station" already says where it is.
  const occupied = new Set(
    shown
      .filter((place) => !place.lagrangePoint)
      .map((place) => place.parentId),
  );

  const anchorOf = (place: LocationStarmapPlace) => {
    if (place === star) return null;
    if (atLagrangePoint(place)) return star ?? null;

    return bodyOf(place) ?? star ?? null;
  };

  const items = shown.map((place): StarmapItem => {
    const role = roleOf(place);
    const anchor = anchorOf(place);

    return {
      key: place.id,
      name: place.name ?? place.slug,
      slug: place.slug,
      kind: place.kind,
      role,
      position: toScene(place.position, origin, UNIT),
      radius: place.radius ? place.radius / UNIT : null,
      color: place.color ?? COLORS[role],
      surface: surfaceOf(place, role),
      texture: place.texture?.largeUrl ?? place.texture?.url ?? null,
      unstable: place.unstable,
      labelled: !place.lagrangePoint || !occupied.has(place.id),
      rank: rankOf(place, role),
      anchor: anchor?.id ?? null,
      distance: anchor ? gap(place.position, anchor.position) : null,
      realRadius: place.radius,
      parentName: place.parentName,
    };
  });

  const orbits = shown.flatMap((place): StarmapOrbit[] => {
    if (
      place.kind !== LocationKindEnum.PLANET &&
      place.kind !== LocationKindEnum.MOON
    ) {
      return [];
    }

    const center = anchorOf(place);
    if (!center) return [];

    return [
      {
        center: center.id,
        body: place.id,
        radius: planarDistance(place.position, center.position) / UNIT,
      },
    ];
  });

  const extent = Math.max(
    1,
    ...items
      .filter((entry) => entry.role === "planet")
      .map((entry) => length(entry.position)),
  );

  return { kind: "system", items, orbits, links: [], extent };
};

/**
 * The chain from the world's centre out to an item: the star, the planet, the
 * moon, the place. What the breadcrumbs show and Escape walks back along.
 */
export const chainOf = (
  scene: StarmapScene,
  key: string | null,
): StarmapItem[] => {
  const byKey = new Map(scene.items.map((entry) => [entry.key, entry]));
  const chain: StarmapItem[] = [];
  let current = key ? byKey.get(key) : undefined;

  while (current) {
    chain.unshift(current);
    current = current.anchor ? byKey.get(current.anchor) : undefined;
  }

  return chain;
};

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
  // Its terrain's elevation and cloud cover, a quarter turn round from the
  // texture.
  elevation: string | null;
  clouds: string | null;
  // The colour of the ground, on a body the newer planet engine paints.
  ground: string | null;
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
  // How close the camera has to be for it to show, in scene units: fully
  // within this, gone at twice it. Measured from its anchor for what stands
  // on or around a body, from itself for what stands alone in the system.
  // Null for what always shows.
  near: number | null;
  nearFrom: "anchor" | "self";
  // A place that matters less than its kind suggests: a comm array rather
  // than a rest stop, a shelter rather than an outpost. Drawn smaller.
  minor: boolean;
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

// What a place can be inside of: a clinic in a station, a venue in a city. A
// district is an area, and the sites in it are places of their own.
const CONTAINERS = new Set<LocationKindEnum>([
  LocationKindEnum.STATION,
  LocationKindEnum.CITY,
  LocationKindEnum.SPACEPORT,
  LocationKindEnum.OUTPOST,
]);

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

// The game has no type for an emergency or aid shelter: it is an outpost the
// game names as one.
const SHELTER = /\bshelter\b/i;

const isShelter = (place: LocationStarmapPlace) =>
  place.kind === LocationKindEnum.OUTPOST && SHELTER.test(place.name ?? "");

// A station a ship cannot dock at: a comm array, a satellite, the rock at a
// Lagrange point.
const isMinorStation = (place: LocationStarmapPlace) =>
  place.kind === LocationKindEnum.STATION && !place.docking && !place.gateway;

const isMinor = (place: LocationStarmapPlace) =>
  isShelter(place) || isMinorStation(place);

const rankOf = (place: LocationStarmapPlace, role: StarmapRole) => {
  if (role !== "place") return RANKS[role];

  // What a reader travels to keeps its name over what is merely there: a
  // station over an outpost, an outpost over a shelter or a mining claim.
  if (isMinor(place)) return 5;
  if (LABELLED_PLACES.has(place.kind) || place.gateway) return 3;
  return place.kind === LocationKindEnum.OUTPOST ? 4 : 5;
};

// Zooming out of a body, what is on and around it goes in steps: shelters
// first, then outposts, then comm arrays and small stations, then cities,
// and last the stations a ship docks at. In the body's radii.
const BODY_REACH = {
  shelter: 2.5,
  place: 5,
  minorStation: 9,
  city: 16,
  station: 40,
  moon: 140,
};

// The same steps for what stands alone in the system, in parts of the
// system's own reach: mining claims, then the rocks and arrays at the
// Lagrange points, and the gateways and rest stops always.
const SYSTEM_REACH = {
  place: 0.12,
  minorStation: 0.35,
};

const bodyReachOf = (place: LocationStarmapPlace) => {
  if (place.kind === LocationKindEnum.MOON) return BODY_REACH.moon;
  if (isShelter(place)) return BODY_REACH.shelter;
  if (isMinorStation(place)) return BODY_REACH.minorStation;
  if (
    place.kind === LocationKindEnum.CITY ||
    place.kind === LocationKindEnum.SPACEPORT
  ) {
    return BODY_REACH.city;
  }
  if (place.kind === LocationKindEnum.STATION) return BODY_REACH.station;
  return BODY_REACH.place;
};

const systemReachOf = (place: LocationStarmapPlace) => {
  if (place.gateway || place.docking) return null;
  if (
    place.kind === LocationKindEnum.STATION ||
    place.kind === LocationKindEnum.JUMP_POINT
  ) {
    return isMinorStation(place) ? SYSTEM_REACH.minorStation : null;
  }
  return SYSTEM_REACH.place;
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
    if (!parent || !CONTAINERS.has(parent.kind) || parent.lagrangePoint) {
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
  stars: Map<string, { color: string | null; unstable: boolean }> = new Map(),
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
      // Drawn as its star, in the star's colour.
      color: stars.get(system.id)?.color ?? COLORS.star,
      surface: null,
      texture: null,
      elevation: null,
      clouds: null,
      ground: null,
      unstable: stars.get(system.id)?.unstable ?? false,
      labelled: true,
      rank: 0,
      near: null,
      nearFrom: "self",
      minor: false,
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

  const extent = Math.max(
    1,
    ...shown
      .filter((place) => place.kind === LocationKindEnum.PLANET)
      .map((place) => length(toScene(place.position, origin, UNIT))),
  );

  const reachOf = (
    place: LocationStarmapPlace,
    role: StarmapRole,
    anchor: LocationStarmapPlace | null,
  ): Pick<StarmapItem, "near" | "nearFrom"> => {
    if (role === "star" || role === "planet") {
      return { near: null, nearFrom: "self" };
    }

    if (anchor && anchor !== star && anchor.radius) {
      return {
        near: (anchor.radius / UNIT) * bodyReachOf(place),
        nearFrom: "anchor",
      };
    }

    const share = systemReachOf(place);
    return { near: share === null ? null : extent * share, nearFrom: "self" };
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
      // As exported: a resized copy would lose what the data maps carry.
      elevation: place.elevation?.url ?? null,
      clouds: place.clouds?.url ?? null,
      ground: place.ground?.largeUrl ?? place.ground?.url ?? null,
      unstable: place.unstable,
      labelled: !place.lagrangePoint || !occupied.has(place.id),
      rank: rankOf(place, role),
      ...reachOf(place, role, anchor),
      minor: isMinor(place),
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

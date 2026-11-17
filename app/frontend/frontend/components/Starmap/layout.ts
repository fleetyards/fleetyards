import {
  LocationKindEnum,
  type Location,
  type LocationJumpPoint,
  type LocationStarmapPlace,
} from "@/services/fyApi";

export type StarmapRole = "system" | "star" | "planet" | "moon" | "place";

export type StarmapVector = [number, number, number];

/**
 * One thing the scene draws, already in scene units. A place the reader can
 * open (a system, planet or moon) carries the slug it opens with.
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
  labelled: boolean;
  enterable: boolean;
  // How far the item is from the centre of its level, in metres.
  distance: number | null;
  realRadius: number | null;
  parentName: string | null;
}

export interface StarmapLink {
  from: StarmapVector;
  to: StarmapVector;
  temporary: boolean;
}

export interface StarmapScene {
  items: StarmapItem[];
  // Circles in the orbital plane, centred on the level's origin.
  orbits: number[];
  links: StarmapLink[];
  extent: number;
}

// Metres per scene unit. A system is tens of gigametres across, a planet's
// surroundings a few hundred megametres: one unit per gigametre and per
// megametre keeps both within the camera's depth range.
export const SYSTEM_UNIT = 1e9;
export const BODY_UNIT = 1e6;

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

const planarDistance = (position: number[], origin: number[]) =>
  Math.hypot(position[0] - origin[0], position[1] - origin[1]);

const roleOf = (place: LocationStarmapPlace): StarmapRole => {
  if (place.kind === LocationKindEnum.STAR) return "star";
  if (place.kind === LocationKindEnum.PLANET) return "planet";
  if (place.kind === LocationKindEnum.MOON) return "moon";
  return "place";
};

const item = (
  place: LocationStarmapPlace,
  origin: number[],
  unit: number,
  labelled: boolean,
): StarmapItem => {
  const role = roleOf(place);
  const offset = place.position.map((value, index) => value - origin[index]);

  return {
    key: place.id,
    name: place.name ?? place.slug,
    slug: place.slug,
    kind: place.kind,
    role,
    position: toScene(place.position, origin, unit),
    radius: place.radius ? place.radius / unit : null,
    color: place.color ?? COLORS[role],
    labelled,
    enterable: role === "planet" || role === "moon",
    distance: length(offset),
    realRadius: place.radius,
    parentName: place.parentName,
  };
};

const extentOf = (items: StarmapItem[], floor: number) =>
  Math.max(floor, ...items.map((entry) => length(entry.position)));

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
      labelled: true,
      enterable: true,
      distance: null,
      realRadius: null,
      parentName: null,
    };
  });

  const seen = new Set<string>();
  const links: StarmapLink[] = [];

  for (const point of jumpPoints) {
    if (!point.destinationSystemId) continue;

    const from = positions.get(point.systemId);
    const to = positions.get(point.destinationSystemId);
    if (!from || !to) continue;

    const pair = [point.systemId, point.destinationSystemId].sort().join(":");
    if (seen.has(pair)) continue;
    seen.add(pair);

    links.push({ from, to, temporary: point.temporary });
  }

  return { items, orbits: [], links, extent: SYSTEMS_RING * 1.8 };
};

const starOf = (places: LocationStarmapPlace[]) =>
  places.find((place) => place.kind === LocationKindEnum.STAR);

/**
 * A system as its star sees it: the planets on their orbits, and what sits
 * directly under the star -- stations, asteroid fields, jump points -- along
 * with the Lagrange points and gateways the game draws at this level too.
 */
export const systemScene = (places: LocationStarmapPlace[]): StarmapScene => {
  const star = starOf(places);
  const origin = star?.position ?? [0, 0, 0];

  const shown = places.filter((place) => {
    if (place === star) return true;
    if (place.kind === LocationKindEnum.PLANET) return true;
    if (place.lagrangePoint || place.gateway) return true;

    return !!star && place.parentId === star.id;
  });

  const items = shown.map((place) =>
    item(
      place,
      origin,
      SYSTEM_UNIT,
      roleOf(place) !== "place" ||
        place.gateway ||
        LABELLED_PLACES.has(place.kind),
    ),
  );

  const orbits = shown
    .filter((place) => place.kind === LocationKindEnum.PLANET)
    .map((place) => planarDistance(place.position, origin) / SYSTEM_UNIT);

  return { items, orbits, links: [], extent: extentOf(items, 1) };
};

const BODY_KINDS = new Set<LocationKindEnum>([
  LocationKindEnum.STAR,
  LocationKindEnum.PLANET,
  LocationKindEnum.MOON,
]);

/**
 * A planet or moon at the centre, its moons on their orbits, and every place
 * that belongs to it rather than to one of its moons: what is on the surface,
 * and what orbits it.
 */
export const bodyScene = (
  places: LocationStarmapPlace[],
  bodySlug: string,
): StarmapScene | null => {
  const body = places.find((place) => place.slug === bodySlug);
  if (!body || !BODY_KINDS.has(body.kind)) return null;

  const byId = new Map(places.map((place) => [place.id, place]));

  const bodyOf = (place: LocationStarmapPlace) => {
    let parent = place.parentId ? byId.get(place.parentId) : undefined;

    while (parent && !BODY_KINDS.has(parent.kind)) {
      parent = parent.parentId ? byId.get(parent.parentId) : undefined;
    }

    return parent;
  };

  // A Lagrange point is drawn with the star, and what sits at it with it.
  const atLagrangePoint = (place: LocationStarmapPlace) => {
    let current: LocationStarmapPlace | undefined = place;

    while (current && !BODY_KINDS.has(current.kind)) {
      if (current.lagrangePoint) return true;
      current = current.parentId ? byId.get(current.parentId) : undefined;
    }

    return false;
  };

  const shown = places.filter((place) => {
    if (place === body) return true;
    if (atLagrangePoint(place)) return false;

    return bodyOf(place)?.id === body.id;
  });

  const items = shown.map((place) =>
    item(
      place,
      body.position,
      BODY_UNIT,
      roleOf(place) !== "place" || LABELLED_PLACES.has(place.kind),
    ),
  );

  const orbits = shown
    .filter((place) => place.kind === LocationKindEnum.MOON)
    .map((place) => planarDistance(place.position, body.position) / BODY_UNIT);

  // Framed on the moons where there are any: what orbits further out is a
  // handful of stations that would shrink the body to a dot.
  const moons = items.filter((entry) => entry.role === "moon");
  const radius = (body.radius ?? BODY_UNIT) / BODY_UNIT;

  return {
    items,
    orbits,
    links: [],
    extent: moons.length
      ? extentOf(moons, radius) * 1.15
      : extentOf(items, radius),
  };
};

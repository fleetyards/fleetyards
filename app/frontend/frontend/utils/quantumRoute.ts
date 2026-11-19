import {
  LocationKindEnum,
  type ComponentQuantumDrive,
  type LocationStarmapPlace,
} from "@/services/fyApi";
import { driveTravelTime } from "@/frontend/utils/travelTimes";

// A jump is refused when its line passes this close to a body's centre, as a
// share of the body's radius. The closest stations orbit at 1.1 radii, so the
// margin stays below that.
export const OBSTRUCTION_FACTOR = 1.05;

// Outposts and cities stand within a few percent of their body's radius,
// terrain included; anything this close counts as standing on the body.
const SURFACE_FACTOR = 1.08;

// A clinic inside a station is the station as far as a jump goes: places this
// close are one stop, kept as the endpoint, the body or whichever comes first.
const SAME_STOP_METRES = 20_000;

const BODY_KINDS = new Set<LocationKindEnum>([
  LocationKindEnum.STAR,
  LocationKindEnum.PLANET,
  LocationKindEnum.MOON,
]);

export interface RouteSystem {
  id: string;
  places: LocationStarmapPlace[];
}

// A jump tunnel between two systems, from the jump point on one side to the
// one on the other.
export interface RouteTunnel {
  from: string;
  to: string;
}

export interface RouteDrive {
  typeData: ComponentQuantumDrive;
  // SCU.
  tankSize: number | null;
}

export interface QuantumLeg {
  kind: "quantum";
  from: LocationStarmapPlace;
  to: LocationStarmapPlace;
  systemId: string;
  // Metres.
  distance: number;
  // Seconds: spooling and the jump itself.
  spool: number;
  travel: number;
  // SCU.
  fuel: number;
}

export interface TunnelLeg {
  kind: "tunnel";
  from: LocationStarmapPlace;
  to: LocationStarmapPlace;
}

export type RouteLeg = QuantumLeg | TunnelLeg;

export interface QuantumRoute {
  legs: RouteLeg[];
  distance: number;
  // Seconds, including the cooldown between consecutive jumps.
  time: number;
  fuel: number;
  exceedsTank: boolean;
}

type Vector = number[];

interface Body {
  id: string;
  position: Vector;
  radius: number;
}

interface Node {
  place: LocationStarmapPlace;
  systemId: string;
  // The body it stands on, for an outpost or a city.
  host: string | null;
}

const subtract = (a: Vector, b: Vector) => a.map((value, i) => value - b[i]);
const dot = (a: Vector, b: Vector) =>
  a.reduce((sum, value, i) => sum + value * b[i], 0);
const distanceBetween = (a: Vector, b: Vector) => Math.hypot(...subtract(a, b));

const isBody = (place: LocationStarmapPlace) =>
  BODY_KINDS.has(place.kind) && !!place.radius;

const bodiesOf = (places: LocationStarmapPlace[]): Body[] =>
  places.filter(isBody).map((place) => ({
    id: place.id,
    position: place.position,
    radius: place.radius as number,
  }));

const hostOf = (place: LocationStarmapPlace, bodies: Body[]) => {
  if (isBody(place)) {
    return null;
  }

  const host = bodies.find(
    (body) =>
      distanceBetween(place.position, body.position) <
      body.radius * SURFACE_FACTOR,
  );

  return host?.id ?? null;
};

/**
 * Whether the straight line from `a` to `b` stays clear of the body.
 */
export const clearsBody = (a: Vector, b: Vector, body: Body) => {
  const along = subtract(b, a);
  const lengthSquared = dot(along, along);
  const t =
    lengthSquared === 0
      ? 0
      : Math.min(
          1,
          Math.max(0, dot(subtract(body.position, a), along) / lengthSquared),
        );
  const closest = a.map((value, i) => value + along[i] * t);

  return (
    distanceBetween(closest, body.position) > body.radius * OBSTRUCTION_FACTOR
  );
};

// Whether `target` is above the horizon of a place standing on `body`.
const aboveHorizon = (position: Vector, target: Vector, body: Body) =>
  dot(subtract(target, position), subtract(position, body.position)) > 0;

const bodyById = (bodies: Body[], id: string | null) =>
  bodies.find((body) => body.id === id);

/**
 * A body itself stands for its orbital markers, reachable and left from any
 * side. A place on its surface sees only what is above its horizon; anything
 * else is reached by jumping to the body first.
 */
const clearsAll = (from: Node, to: Node, bodies: Body[]) => {
  const a = from.place.position;
  const b = to.place.position;
  const fromHost = bodyById(bodies, from.host);
  const toHost = bodyById(bodies, to.host);

  if (
    fromHost &&
    fromHost.id !== to.place.id &&
    !aboveHorizon(a, b, fromHost)
  ) {
    return false;
  }

  if (toHost && toHost.id !== from.place.id && !aboveHorizon(b, a, toHost)) {
    return false;
  }

  return bodies.every(
    (body) =>
      body.id === from.place.id ||
      body.id === to.place.id ||
      body === fromHost ||
      body === toHost ||
      clearsBody(a, b, body),
  );
};

// mSCU per gigametre.
const legFuel = (drive: RouteDrive, metres: number) =>
  ((drive.typeData.quantumFuelConsumption || 0) * (metres / 1e9)) / 1000;

const quantumLeg = (
  from: Node,
  to: Node,
  drive: RouteDrive,
): QuantumLeg | null => {
  const distance = distanceBetween(from.place.position, to.place.position);
  const travel = driveTravelTime(drive.typeData, distance / 1000);

  if (travel === undefined || !Number.isFinite(travel)) {
    return null;
  }

  return {
    kind: "quantum",
    from: from.place,
    to: to.place,
    systemId: from.systemId,
    distance,
    spool: drive.typeData.spoolUpTime || 0,
    travel,
    fuel: legFuel(drive, distance),
  };
};

// Every jump pays the cooldown that keeps the drive from spooling the next,
// so a detour is weighed against the jumps it adds. A tunnel's transit is not
// the drive's to time and costs nothing.
const legCost = (leg: RouteLeg, drive: RouteDrive) =>
  leg.kind === "tunnel"
    ? 0
    : leg.spool + leg.travel + (drive.typeData.cooldownTime || 0);

/**
 * The fastest chain of quantum jumps from one place to another: every jump a
 * straight line clear of the stars, planets and moons of its system, and a
 * system left only through a jump tunnel. Null when no chain exists or the
 * drive has no speed.
 */
export const planRoute = ({
  systems,
  tunnels = [],
  drive,
  from,
  to,
}: {
  systems: RouteSystem[];
  tunnels?: RouteTunnel[];
  drive: RouteDrive;
  from: string;
  to: string;
}): QuantumRoute | null => {
  if (!drive.typeData.driveSpeed) {
    return null;
  }

  const nodes = new Map<string, Node>();
  const bodiesBySystem = new Map<string, Body[]>();
  const nodesBySystem = new Map<string, Node[]>();
  const tunnelEnds = new Set(
    tunnels.flatMap((tunnel) => [tunnel.from, tunnel.to]),
  );

  systems.forEach((system) => {
    const bodies = bodiesOf(system.places);
    bodiesBySystem.set(system.id, bodies);

    const pinned = (place: LocationStarmapPlace) =>
      tunnelEnds.has(place.id) || place.id === from || place.id === to;
    const candidates = system.places
      .filter((place) => place.quantumTravelDestination || pinned(place))
      .sort(
        (a, b) =>
          Number(pinned(b)) - Number(pinned(a)) ||
          Number(isBody(b)) - Number(isBody(a)),
      );

    const systemNodes: Node[] = [];
    candidates.forEach((place) => {
      const sameStop =
        !pinned(place) &&
        systemNodes.some(
          (node) =>
            distanceBetween(node.place.position, place.position) <
            SAME_STOP_METRES,
        );

      if (!sameStop) {
        systemNodes.push({
          place,
          systemId: system.id,
          host: hostOf(place, bodies),
        });
      }
    });

    systemNodes.forEach((node) => nodes.set(node.place.id, node));
    nodesBySystem.set(system.id, systemNodes);
  });

  if (!nodes.has(from) || !nodes.has(to)) {
    return null;
  }

  const tunnelsFrom = new Map<string, string[]>();
  tunnels.forEach((tunnel) => {
    tunnelsFrom.set(tunnel.from, [
      ...(tunnelsFrom.get(tunnel.from) || []),
      tunnel.to,
    ]);
  });

  const target = nodes.get(to) as Node;
  const jumpTime = (a: Node, b: Node) =>
    driveTravelTime(
      drive.typeData,
      distanceBetween(a.place.position, b.place.position) / 1000,
    ) || 0;

  // A* towards the destination. Within its system no chain of jumps beats the
  // straight line, since the drive covers one long jump faster than the same
  // distance in parts. A route that leaves the system comes back through one
  // of its tunnel ends and jumps on from there, so the closest of those bounds
  // it too.
  const viaTunnel = Math.min(
    Infinity,
    ...(nodesBySystem.get(target.systemId) || [])
      .filter((node) => tunnelEnds.has(node.place.id))
      .map((node) => jumpTime(node, target)),
  );
  const estimate = (node: Node) =>
    node.systemId === target.systemId
      ? Math.min(jumpTime(node, target), viaTunnel)
      : Number.isFinite(viaTunnel)
        ? viaTunnel
        : 0;
  const estimates = new Map<string, number>();
  const estimateOf = (id: string) => {
    if (!estimates.has(id)) {
      estimates.set(id, estimate(nodes.get(id) as Node));
    }

    return estimates.get(id) as number;
  };

  const cost = new Map<string, number>([[from, 0]]);
  const via = new Map<string, RouteLeg>();
  const done = new Set<string>();

  // The estimate never overshoots but is not consistent across a tunnel, so a
  // place already settled is reopened when a cheaper way to it turns up.
  const relax = (leg: RouteLeg, base: number) => {
    const next = base + legCost(leg, drive);

    if (next < (cost.get(leg.to.id) ?? Infinity)) {
      cost.set(leg.to.id, next);
      via.set(leg.to.id, leg);
      done.delete(leg.to.id);
    }
  };

  // Dense graph: every destination can see most others, so a linear scan for
  // the cheapest open node beats a heap.
  for (;;) {
    let current: string | null = null;
    let best = Infinity;
    let rank = Infinity;

    cost.forEach((value, id) => {
      const ranked = value + estimateOf(id);

      if (!done.has(id) && ranked < rank) {
        rank = ranked;
        best = value;
        current = id;
      }
    });

    if (current === null || current === to) {
      break;
    }

    done.add(current);
    const node = nodes.get(current) as Node;
    const bodies = bodiesBySystem.get(node.systemId) || [];

    (nodesBySystem.get(node.systemId) || []).forEach((next) => {
      if (next === node || next.place.id === from) {
        return;
      }

      if (!clearsAll(node, next, bodies)) {
        return;
      }

      const leg = quantumLeg(node, next, drive);

      if (leg) {
        relax(leg, best);
      }
    });

    (tunnelsFrom.get(current) || []).forEach((targetId) => {
      const exit = nodes.get(targetId);

      if (exit && targetId !== from) {
        relax({ kind: "tunnel", from: node.place, to: exit.place }, best);
      }
    });
  }

  if (!via.has(to) && from !== to) {
    return null;
  }

  const legs: RouteLeg[] = [];
  for (let id = to; id !== from;) {
    const leg = via.get(id) as RouteLeg;
    legs.unshift(leg);
    id = leg.from.id;
  }

  return summarise(legs, drive);
};

const summarise = (legs: RouteLeg[], drive: RouteDrive): QuantumRoute => {
  const jumps = legs.filter((leg): leg is QuantumLeg => leg.kind === "quantum");
  const fuel = jumps.reduce((sum, leg) => sum + leg.fuel, 0);
  const cooldowns =
    Math.max(0, jumps.length - 1) * (drive.typeData.cooldownTime || 0);

  return {
    legs,
    distance: jumps.reduce((sum, leg) => sum + leg.distance, 0),
    time:
      jumps.reduce((sum, leg) => sum + leg.spool + leg.travel, 0) + cooldowns,
    fuel,
    exceedsTank: drive.tankSize !== null && fuel > drive.tankSize,
  };
};

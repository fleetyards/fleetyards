import type { LocationJumpPoint } from "@/services/fyApi";

export interface JumpConnection {
  key: string;
  systemIds: [string, string];
  // The jump point on each side, by the id of the system it is in. A side is
  // missing when the data has only the other end.
  ends: Record<string, LocationJumpPoint | undefined>;
  // Announced, with no jump point in the game files at either end.
  planned?: boolean;
}

// How a connection is drawn: solid, dotted, dashed.
export type JumpStyle = "inGame" | "temporary" | "planned";

// A chip on a card: a jump point to go to, or, without one, the name of the
// system a connection leads to. No style for a way off the page.
export interface JumpChip {
  key: string;
  name: string;
  style: JumpStyle | null;
  jumpPoint?: LocationJumpPoint;
}

export interface JumpLane {
  connection: JumpConnection;
  // Positions in the order the systems are drawn in, upper before lower.
  upper: number;
  lower: number;
  column: number;
}

export interface JumpLaneLayout {
  order: string[];
  lanes: JumpLane[];
  columns: number;
}

// Every order of the systems is tried up to this many: 8! is 40,320 layouts,
// which is still instant. Past it the systems keep the order they came in.
export const MAX_ORDERED_SYSTEMS = 8;

// The jump points that join two of the listed systems, one connection per
// pair however many records each side has.
export const jumpConnections = (
  systemIds: string[],
  jumpPoints: LocationJumpPoint[],
): JumpConnection[] => {
  const listed = new Set(systemIds);
  const connections = new Map<string, JumpConnection>();

  jumpPoints.forEach((jumpPoint) => {
    const from = jumpPoint.systemId;
    const to = jumpPoint.destinationSystemId;

    if (!to || to === from || !listed.has(from) || !listed.has(to)) {
      return;
    }

    const systemPair = [from, to].sort() as [string, string];
    const key = systemPair.join(":");
    const connection = connections.get(key) ?? {
      key,
      systemIds: systemPair,
      ends: {},
    };

    connection.ends[from] ??= jumpPoint;
    connections.set(key, connection);
  });

  return [...connections.values()];
};

// The jump points no line ends at, by the system they are in: those that lead
// off the page, and a second jump point to a system a line already joins.
export const unjoinedJumpPoints = (
  jumpPoints: LocationJumpPoint[],
  connections: JumpConnection[],
): Record<string, LocationJumpPoint[]> => {
  const joined = new Set(
    connections.flatMap((connection) =>
      Object.values(connection.ends).flatMap((end) =>
        end ? [end.location.id] : [],
      ),
    ),
  );

  return jumpPoints.reduce<Record<string, LocationJumpPoint[]>>(
    (unjoined, jumpPoint) => {
      if (!joined.has(jumpPoint.location.id)) {
        (unjoined[jumpPoint.systemId] ??= []).push(jumpPoint);
      }

      return unjoined;
    },
    {},
  );
};

// Planned while it is only announced or either side is a placeholder;
// temporary when a jump point its line ends at runs on another tunnel's
// record. Read off the ends alone, never a second record the line ignores.
export const connectionStyle = (
  connection: JumpConnection,
  placeholderIds: Set<string>,
): JumpStyle => {
  if (
    connection.planned ||
    connection.systemIds.some((id) => placeholderIds.has(id))
  ) {
    return "planned";
  }

  return Object.values(connection.ends).some((end) => end?.temporary)
    ? "temporary"
    : "inGame";
};

// A jump point no line ends at, by itself.
export const jumpPointStyle = (
  jumpPoint: LocationJumpPoint,
  placeholderIds: Set<string>,
): JumpStyle | null => {
  const to = jumpPoint.destinationSystemId;

  if (!to) {
    return null;
  }

  if (placeholderIds.has(to)) {
    return "planned";
  }

  return jumpPoint.temporary ? "temporary" : "inGame";
};

const assignColumns = (order: string[], connections: JumpConnection[]) => {
  const position = new Map(order.map((id, index) => [id, index]));

  const spans = connections
    .map((connection) => {
      const [upper, lower] = connection.systemIds
        .map((id) => position.get(id) ?? 0)
        .sort((a, b) => a - b);

      return { connection, upper, lower };
    })
    .sort(
      (a, b) => a.lower - a.upper - (b.lower - b.upper) || a.upper - b.upper,
    );

  // A column is held from the upper card to the lower one, both included: two
  // lines that met at one card in one column would read as a single line
  // passing through it.
  const taken: [number, number][][] = [];

  const lanes = spans.map((span) => {
    let column = taken.findIndex((ranges) =>
      ranges.every(
        ([upper, lower]) => span.lower < upper || span.upper > lower,
      ),
    );

    if (column === -1) {
      column = taken.length;
      taken.push([]);
    }

    taken[column].push([span.upper, span.lower]);

    return { ...span, column };
  });

  return {
    lanes,
    columns: taken.length,
    length: spans.reduce((sum, span) => sum + span.lower - span.upper, 0),
  };
};

// In lexicographic order of the positions, so among equally good orders the
// first one found is the closest to the order the systems came in.
function* permutations(ids: string[]): Generator<string[]> {
  if (ids.length <= 1) {
    yield ids;
    return;
  }

  for (let index = 0; index < ids.length; index += 1) {
    const rest = [...ids.slice(0, index), ...ids.slice(index + 1)];

    for (const tail of permutations(rest)) {
      yield [ids[index], ...tail];
    }
  }
}

// The order that needs the fewest columns, then the shortest lines. Ties keep
// the order the systems came in, so the page does not reshuffle between loads.
export const jumpLaneLayout = (
  systemIds: string[],
  connections: JumpConnection[],
): JumpLaneLayout => {
  if (systemIds.length > MAX_ORDERED_SYSTEMS) {
    const { lanes, columns } = assignColumns(systemIds, connections);

    return { order: systemIds, lanes, columns };
  }

  let best: (ReturnType<typeof assignColumns> & { order: string[] }) | null =
    null;

  for (const order of permutations(systemIds)) {
    const candidate = assignColumns(order, connections);

    if (
      !best ||
      candidate.columns < best.columns ||
      (candidate.columns === best.columns && candidate.length < best.length)
    ) {
      best = { ...candidate, order };
    }
  }

  return {
    order: best?.order ?? systemIds,
    lanes: best?.lanes ?? [],
    columns: best?.columns ?? 0,
  };
};

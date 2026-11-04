// Every layout turns ships into centre positions in metres, so the renderer never
// has to know which one is active and a position survives a change of scale.

export interface FleetchartLayoutShip {
  id: string;
  width: number;
  height: number;
  // Room for a label to the left of the ship, and the height that label needs.
  gutter?: number;
  minHeight?: number;
  // Ships of one group stay together, under a heading this wide.
  group?: string;
  headingWidth?: number;
  // Overrides the spacing around this ship.
  padding?: number;
}

export interface FleetchartGroupHeading {
  title: string;
  x: number;
  y: number;
}

export interface FleetchartPosition {
  x: number;
  y: number;
}

export type FleetchartPositions = Record<string, FleetchartPosition>;

export interface FleetchartBounds {
  minX: number;
  minY: number;
  width: number;
  height: number;
}

export interface FleetchartScreen {
  width: number;
  height: number;
}

// At 4 pixels per metre these are the chart's established 20px padding around a
// ship and 30px between columns.
export const SHIP_PADDING = 5;
const COLUMN_GAP_RATIO = 1.5;
const HEADING_ROOM = 15;

const MIN_FACTOR = 1;
const MAX_FACTOR = 20;
const FACTOR_STEP = 0.25;

const paddingOf = (ship: FleetchartLayoutShip) => ship.padding ?? SHIP_PADDING;

const boxWidth = (ship: FleetchartLayoutShip) =>
  ship.width + (ship.gutter || 0) + paddingOf(ship);

const boxHeight = (ship: FleetchartLayoutShip) =>
  Math.max(ship.height, ship.minHeight || 0) + paddingOf(ship);

const columnGapOf = (ships: FleetchartLayoutShip[]) =>
  (ships[0]?.padding ?? SHIP_PADDING) * COLUMN_GAP_RATIO;

const columnWidthOf = (column: FleetchartLayoutShip[]) =>
  Math.max(
    ...column.map((ship) => Math.max(boxWidth(ship), ship.headingWidth || 0)),
  );

const placeInBox = (
  ship: FleetchartLayoutShip,
  boxRight: number,
  centreY: number,
): FleetchartPosition => ({
  x: boxRight - paddingOf(ship) / 2 - ship.width / 2,
  y: centreY,
});

const splitColumns = (
  ships: FleetchartLayoutShip[],
  maxColumnHeight: number,
) => {
  const columns: FleetchartLayoutShip[][] = [];
  let columnHeight = 0;

  ships.forEach((ship) => {
    const column = columns[columns.length - 1];
    const fits =
      !!column &&
      column[0].group === ship.group &&
      columnHeight + boxHeight(ship) - paddingOf(ship) <= maxColumnHeight;

    if (!fits) {
      columns.push([]);
      columnHeight = 0;
    }

    columnHeight += boxHeight(ship);
    columns[columns.length - 1].push(ship);
  });

  return columns;
};

const columnsSize = (columns: FleetchartLayoutShip[][]) => {
  const widths = columns.map(columnWidthOf);
  const heights = columns.map((column) =>
    column.reduce((sum, ship) => sum + boxHeight(ship), 0),
  );

  return {
    width:
      widths.reduce((sum, width) => sum + width, 0) +
      columnGapOf(columns[0] ?? []) * Math.max(columns.length - 1, 0),
    height: Math.max(0, ...heights),
  };
};

// The screen-height factor whose chart comes closest to the screen's own
// proportions, so a large fleet fits one view instead of a long strip. Never
// below 1x: a small fleet already fits and would only be squeezed.
export const autoScreenHeightFactor = (
  ships: FleetchartLayoutShip[],
  screen: FleetchartScreen,
  columnHeight: (factor: number) => number,
) => {
  if (!ships.length || !screen.width || !screen.height) {
    return MIN_FACTOR;
  }

  const target = screen.width / screen.height;
  let best = MIN_FACTOR;
  let bestDistance = Infinity;

  for (let factor = MIN_FACTOR; factor <= MAX_FACTOR; factor += FACTOR_STEP) {
    const columns = splitColumns(ships, columnHeight(factor));
    const { width, height } = columnsSize(columns);
    const distance = Math.abs(Math.log(width / height / target));

    if (distance < bestDistance) {
      best = factor;
      bestDistance = distance;
    }

    if (columns.length <= 1) {
      break;
    }
  }

  return best;
};

// Ships run in the given order into columns from the left, each column drawn
// with its last ship on top and right-aligned.
export const arrangeColumns = (
  ships: FleetchartLayoutShip[],
  maxColumnHeight: number,
  { centred = false }: { centred?: boolean } = {},
): FleetchartPositions => {
  const positions: FleetchartPositions = {};
  const headingRoom = ships.some((ship) => ship.group) ? HEADING_ROOM : 0;
  let columnLeft = 0;

  splitColumns(ships, maxColumnHeight).forEach((column) => {
    const columnWidth = columnWidthOf(column);
    let top = headingRoom;

    [...column].reverse().forEach((ship) => {
      const boxRight = centred
        ? columnLeft + (columnWidth + boxWidth(ship)) / 2
        : columnLeft + columnWidth;

      positions[ship.id] = placeInBox(
        ship,
        boxRight,
        top + boxHeight(ship) / 2,
      );

      top += boxHeight(ship);
    });

    columnLeft += columnWidth + columnGapOf(ships);
  });

  return positions;
};

// Ships run in the given order into rows centred on `maxRowWidth`, each ship
// vertically centred in its row. A ship too long for a row starts at its left
// edge, so it cannot push every other row off the opening view.
export const arrangeClassic = (
  ships: FleetchartLayoutShip[],
  maxRowWidth: number,
): FleetchartPositions => {
  const rows: FleetchartLayoutShip[][] = [];
  let rowWidth = 0;

  ships.forEach((ship) => {
    const row = rows[rows.length - 1];

    if (
      !row ||
      row[0].group !== ship.group ||
      rowWidth + boxWidth(ship) > maxRowWidth
    ) {
      rows.push([]);
      rowWidth = 0;
    }

    rowWidth += boxWidth(ship);
    rows[rows.length - 1].push(ship);
  });

  const positions: FleetchartPositions = {};
  let top = 0;

  rows.forEach((row, index) => {
    if (row[0].group && row[0].group !== rows[index - 1]?.[0].group) {
      top += HEADING_ROOM;
    }

    const width = row.reduce((sum, ship) => sum + boxWidth(ship), 0);
    const height = Math.max(...row.map((ship) => boxHeight(ship)));
    let left = Math.max((maxRowWidth - width) / 2, 0);

    row.forEach((ship) => {
      left += boxWidth(ship);
      positions[ship.id] = placeInBox(ship, left, top + height / 2);
    });

    top += height;
  });

  return positions;
};

interface SkylineSegment {
  x: number;
  y: number;
  width: number;
}

const raiseSkyline = (
  skyline: SkylineSegment[],
  x: number,
  width: number,
  y: number,
) => {
  const raised = skyline.flatMap((segment) => {
    const end = segment.x + segment.width;

    if (end <= x || segment.x >= x + width) {
      return [segment];
    }

    return [
      ...(segment.x < x ? [{ ...segment, width: x - segment.x }] : []),
      ...(end > x + width
        ? [{ x: x + width, y: segment.y, width: end - x - width }]
        : []),
    ];
  });

  return [...raised, { x, y, width }]
    .sort((a, b) => a.x - b.x)
    .reduce<SkylineSegment[]>((merged, segment) => {
      const previous = merged[merged.length - 1];

      if (previous && previous.y === segment.y) {
        previous.width += segment.width;
      } else {
        merged.push({ ...segment });
      }

      return merged;
    }, []);
};

interface PackedBox {
  id: string;
  width: number;
  height: number;
}

interface Packing {
  spots: Record<string, { x: number; y: number }>;
  width: number;
  height: number;
}

// Drops each box onto the lowest free spot along the top edge of what is already
// placed, which is what fills the space beside and under a large one. Tallest
// first is what keeps that tight.
const packAt = (boxes: PackedBox[], width: number): Packing => {
  const spots: Packing["spots"] = {};
  let skyline: SkylineSegment[] = [{ x: 0, y: 0, width }];
  let usedWidth = 0;

  [...boxes]
    .sort((a, b) => b.height - a.height || b.width - a.width)
    .forEach((box) => {
      let spot: { x: number; y: number } | undefined;

      skyline.forEach((segment) => {
        if (segment.x + box.width > width) {
          return;
        }

        const y = Math.max(
          ...skyline
            .filter(
              (other) =>
                other.x < segment.x + box.width &&
                other.x + other.width > segment.x,
            )
            .map((other) => other.y),
        );

        if (!spot || y < spot.y) {
          spot = { x: segment.x, y };
        }
      });

      const { x, y } = spot as { x: number; y: number };

      spots[box.id] = { x, y };
      usedWidth = Math.max(usedWidth, x + box.width);
      skyline = raiseSkyline(skyline, x, box.width, y + box.height);
    });

  return {
    spots,
    width: usedWidth,
    height: Math.max(...skyline.map((segment) => segment.y)),
  };
};

const PACKED_WIDTH_FACTORS = [0.8, 0.9, 1, 1.1, 1.25, 1.5, 1.75, 2, 2.5];

// Tries a range of widths and keeps the packing that draws largest once fitted to
// the screen, and of those the one taking the least area.
const bestPacking = (boxes: PackedBox[], aspectRatio: number): Packing => {
  const widest = Math.max(...boxes.map((box) => box.width));
  const area = boxes.reduce((sum, box) => sum + box.width * box.height, 0);
  const ideal = Math.sqrt(area * aspectRatio);

  const fit = ({ width, height }: Packing) =>
    Math.max(width, height * aspectRatio);

  return [
    widest,
    ...PACKED_WIDTH_FACTORS.map((factor) => ideal * factor),
    ...PACKED_WIDTH_FACTORS.map((factor) => widest * factor),
  ]
    .filter((width) => width >= widest)
    .map((width) => packAt(boxes, width))
    .reduce((best, packing) => {
      const difference = fit(packing) - fit(best);

      if (Math.abs(difference) < fit(best) * 0.01) {
        return packing.width * packing.height < best.width * best.height
          ? packing
          : best;
      }

      return difference < 0 ? packing : best;
    });
};

// Fills the available space rather than keeping to any order, so the sort option
// does not apply. Each group is packed into a block of its own under its heading,
// and the blocks are packed the same way, so a small group can sit beside a large
// one.
export const arrangePacked = (
  ships: FleetchartLayoutShip[],
  aspectRatio: number,
): FleetchartPositions => {
  if (!ships.length) {
    return {};
  }

  const byGroup = new Map<string, FleetchartLayoutShip[]>();

  ships.forEach((ship) => {
    const key = ship.group ?? "";

    byGroup.set(key, [...(byGroup.get(key) ?? []), ship]);
  });

  const toBox = (ship: FleetchartLayoutShip): PackedBox => ({
    id: ship.id,
    width: boxWidth(ship),
    height: boxHeight(ship),
  });

  const blocks = [...byGroup].map(([key, members]) => ({
    key,
    members,
    packing: bestPacking(members.map(toBox), aspectRatio),
    headingRoom: key ? HEADING_ROOM : 0,
    headingWidth: members[0].headingWidth || 0,
  }));

  const groupGap = byGroup.size > 1 ? SHIP_PADDING * 2 : 0;

  const layoutOfBlocks = bestPacking(
    blocks.map((block) => ({
      id: block.key,
      width: Math.max(block.packing.width, block.headingWidth) + groupGap,
      height: block.packing.height + block.headingRoom + groupGap,
    })),
    aspectRatio,
  );

  const positions: FleetchartPositions = {};

  blocks.forEach(({ key, members, packing, headingRoom }) => {
    const origin = layoutOfBlocks.spots[key];

    members.forEach((ship) => {
      const { x, y } = packing.spots[ship.id];

      positions[ship.id] = placeInBox(
        ship,
        origin.x + x + boxWidth(ship),
        origin.y + headingRoom + y + boxHeight(ship) / 2,
      );
    });
  });

  return positions;
};

// The area the ships cover, labels and padding included, for sizing the scene
// and so an export contains them whatever their coordinates are.
export const boundsOf = (
  ships: FleetchartLayoutShip[],
  positions: FleetchartPositions,
): FleetchartBounds => {
  const placed = ships.filter((ship) => positions[ship.id]);

  if (!placed.length) {
    return { minX: 0, minY: 0, width: 0, height: 0 };
  }

  const left = (ship: FleetchartLayoutShip) =>
    positions[ship.id].x -
    ship.width / 2 -
    (ship.gutter || 0) -
    paddingOf(ship) / 2;
  const right = (ship: FleetchartLayoutShip) =>
    positions[ship.id].x + ship.width / 2 + paddingOf(ship) / 2;
  const top = (ship: FleetchartLayoutShip) =>
    positions[ship.id].y -
    boxHeight(ship) / 2 -
    (ship.group ? HEADING_ROOM : 0);
  const bottom = (ship: FleetchartLayoutShip) =>
    positions[ship.id].y + boxHeight(ship) / 2;

  const minX = Math.min(...placed.map(left));
  const minY = Math.min(...placed.map(top));

  return {
    minX,
    minY,
    width: Math.max(...placed.map(right)) - minX,
    height: Math.max(...placed.map(bottom)) - minY,
  };
};

// One heading per group, above the top left of the space its ships take.
export const groupHeadings = (
  ships: FleetchartLayoutShip[],
  positions: FleetchartPositions,
): FleetchartGroupHeading[] => {
  const groups = new Map<string, FleetchartLayoutShip[]>();

  ships.forEach((ship) => {
    if (ship.group && positions[ship.id]) {
      groups.set(ship.group, [...(groups.get(ship.group) ?? []), ship]);
    }
  });

  return [...groups].map(([title, members]) => {
    const { minX, minY, width } = boundsOf(members, positions);
    const headingWidth = members[0].headingWidth || 0;

    return {
      title,
      // A heading wider than its ships ends where they do, as they sit at the
      // right of their column and it would otherwise reach into the next one.
      x: Math.min(minX, minX + width - headingWidth),
      y: minY + HEADING_ROOM / 2,
    };
  });
};

// Widens the bounds to a full row, so rows stay centred on the screen rather than
// only on each other when the scene is drawn from its bounds.
export const withRowWidth = (
  bounds: FleetchartBounds,
  rowWidth: number,
): FleetchartBounds => {
  const minX = Math.min(bounds.minX, 0);

  return {
    ...bounds,
    minX,
    width: Math.max(bounds.minX + bounds.width, rowWidth) - minX,
  };
};

const GRID_CELLS = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000];

// The smallest round cell, in metres, that stays readable at this zoom.
export const gridCellFor = (pixelsPerMetre: number, minCellPixels = 40) =>
  GRID_CELLS.find((cell) => cell * pixelsPerMetre >= minCellPixels) ??
  GRID_CELLS[GRID_CELLS.length - 1];

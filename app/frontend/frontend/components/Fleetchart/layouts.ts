// Every layout turns ships into centre positions in metres, so the renderer never
// has to know which one is active and a position survives a change of scale.

export interface FleetchartLayoutShip {
  id: string;
  width: number;
  height: number;
  // Room for a label to the left of the ship.
  gutter?: number;
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
const SHIP_PADDING = 5;
const COLUMN_GAP = 7.5;

const MIN_FACTOR = 1;
const MAX_FACTOR = 20;
const FACTOR_STEP = 0.25;

const boxWidth = (ship: FleetchartLayoutShip) =>
  ship.width + (ship.gutter || 0) + SHIP_PADDING;

const boxHeight = (ship: FleetchartLayoutShip) => ship.height + SHIP_PADDING;

const placeInBox = (
  ship: FleetchartLayoutShip,
  boxRight: number,
  centreY: number,
): FleetchartPosition => ({
  x: boxRight - SHIP_PADDING / 2 - ship.width / 2,
  y: centreY,
});

const splitColumns = (
  ships: FleetchartLayoutShip[],
  maxColumnHeight: number,
) => {
  const columns: FleetchartLayoutShip[][] = [];
  let columnHeight = 0;

  ships.forEach((ship) => {
    const fits =
      columns.length > 0 && columnHeight + ship.height <= maxColumnHeight;

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
  const widths = columns.map((column) =>
    Math.max(...column.map((ship) => boxWidth(ship))),
  );
  const heights = columns.map((column) =>
    column.reduce((sum, ship) => sum + boxHeight(ship), 0),
  );

  return {
    width:
      widths.reduce((sum, width) => sum + width, 0) +
      COLUMN_GAP * Math.max(columns.length - 1, 0),
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
): FleetchartPositions => {
  const positions: FleetchartPositions = {};
  let columnLeft = 0;

  splitColumns(ships, maxColumnHeight).forEach((column) => {
    const columnWidth = Math.max(...column.map((ship) => boxWidth(ship)));
    let top = 0;

    [...column].reverse().forEach((ship) => {
      positions[ship.id] = placeInBox(
        ship,
        columnLeft + columnWidth,
        top + boxHeight(ship) / 2,
      );

      top += boxHeight(ship);
    });

    columnLeft += columnWidth + COLUMN_GAP;
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
    if (!rows.length || rowWidth + boxWidth(ship) > maxRowWidth) {
      rows.push([]);
      rowWidth = 0;
    }

    rowWidth += boxWidth(ship);
    rows[rows.length - 1].push(ship);
  });

  const positions: FleetchartPositions = {};
  let top = 0;

  rows.forEach((row) => {
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
    SHIP_PADDING / 2;
  const right = (ship: FleetchartLayoutShip) =>
    positions[ship.id].x + ship.width / 2 + SHIP_PADDING / 2;
  const top = (ship: FleetchartLayoutShip) =>
    positions[ship.id].y - boxHeight(ship) / 2;
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

const GRID_CELLS = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000];

// The smallest round cell, in metres, that stays readable at this zoom.
export const gridCellFor = (pixelsPerMetre: number, minCellPixels = 40) =>
  GRID_CELLS.find((cell) => cell * pixelsPerMetre >= minCellPixels) ??
  GRID_CELLS[GRID_CELLS.length - 1];

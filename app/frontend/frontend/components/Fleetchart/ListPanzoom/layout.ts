export type FleetchartItemSize = {
  width: number;
  height: number;
};

// Mirrors the spacing in index.scss and Item/index.scss: an item's padding on
// either side, and the margin between columns. Labels, off by default, are
// left out.
const ITEM_GAP = 20;
const ITEM_PADDING = 20;
const COLUMN_GAP = 30;

const MIN_FACTOR = 1;
const MAX_FACTOR = 20;
const FACTOR_STEP = 0.25;

// Fills columns top to bottom, starting a new one once the next item would
// overflow `maxColumnHeight`. Returns the item indexes per column.
export const layoutColumns = (
  sizes: FleetchartItemSize[],
  maxColumnHeight: number,
) => {
  const columns: number[][] = [];
  let index = 0;
  let columnHeight = 0;

  sizes.forEach((size, itemIndex) => {
    columnHeight += size.height;

    if (columnHeight > maxColumnHeight) {
      columnHeight = size.height;
      index += 1;
    }

    columnHeight += ITEM_GAP;

    columns[index] = [...(columns[index] || []), itemIndex];
  });

  return columns.filter(Boolean);
};

export const chartSize = (sizes: FleetchartItemSize[], columns: number[][]) => {
  const widths = columns.map((column) =>
    Math.max(...column.map((index) => sizes[index].width + ITEM_PADDING)),
  );
  const heights = columns.map((column) =>
    column.reduce((sum, index) => sum + sizes[index].height + ITEM_GAP, 0),
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
  sizes: FleetchartItemSize[],
  screen: FleetchartItemSize,
  columnHeight: (factor: number) => number,
) => {
  if (!sizes.length || !screen.width || !screen.height) {
    return MIN_FACTOR;
  }

  const target = screen.width / screen.height;
  let best = MIN_FACTOR;
  let bestDistance = Infinity;

  for (let factor = MIN_FACTOR; factor <= MAX_FACTOR; factor += FACTOR_STEP) {
    const columns = layoutColumns(sizes, columnHeight(factor));
    const { width, height } = chartSize(sizes, columns);
    const distance = height ? Math.abs(Math.log(width / height / target)) : 0;

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

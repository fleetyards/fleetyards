import { describe, expect, it } from "vitest";
import {
  arrangeClassic,
  arrangeColumns,
  autoScreenHeightFactor,
  boundsOf,
  gridCellFor,
  type FleetchartLayoutShip,
} from "./layouts";

const ship = (
  id: string,
  width = 100,
  height = 20,
  gutter = 0,
): FleetchartLayoutShip => ({ id, width, height, gutter });

describe("arrangeColumns", () => {
  it("starts a new column once the next ship overflows", () => {
    const positions = arrangeColumns([ship("a"), ship("b"), ship("c")], 50);

    expect(positions.a.x).toBe(positions.b.x);
    expect(positions.c.x).toBeGreaterThan(positions.a.x);
  });

  it("draws a column's last ship on top", () => {
    const positions = arrangeColumns([ship("a"), ship("b")], 500);

    expect(positions.b.y).toBeLessThan(positions.a.y);
  });

  it("right-aligns ships within their column", () => {
    const positions = arrangeColumns([ship("a", 40), ship("b", 100)], 500);

    expect(positions.a.x + 20).toBe(positions.b.x + 50);
  });

  it("keeps a ship taller than the column in a column of its own", () => {
    const positions = arrangeColumns([ship("a", 100, 900), ship("b")], 50);

    expect(positions.b.x).toBeGreaterThan(positions.a.x);
  });

  it("spaces small ships far enough apart for their labels", () => {
    const positions = arrangeColumns(
      [
        { ...ship("a", 100, 5), minHeight: 20 },
        { ...ship("b", 100, 5), minHeight: 20 },
      ],
      500,
    );

    expect(positions.a.y - positions.b.y).toBe(25);
  });

  it("widens a column for a label so it cannot reach the next column", () => {
    const without = arrangeColumns([ship("a"), ship("b")], 1);
    const withLabel = arrangeColumns([ship("a"), ship("b", 100, 20, 60)], 1);

    expect(withLabel.b.x - withLabel.a.x).toBe(without.b.x - without.a.x + 60);
  });
});

describe("arrangeClassic", () => {
  it("wraps a row once the next ship does not fit", () => {
    const positions = arrangeClassic([ship("a"), ship("b"), ship("c")], 220);

    expect(positions.a.y).toBe(positions.b.y);
    expect(positions.c.y).toBeGreaterThan(positions.a.y);
  });

  it("centres a shorter row under a longer one", () => {
    const positions = arrangeClassic([ship("a"), ship("b"), ship("c")], 220);

    expect(positions.c.x).toBe((positions.a.x + positions.b.x) / 2);
  });

  it("does not let an oversized ship move the other rows", () => {
    const positions = arrangeClassic(
      [ship("a", 100), ship("huge", 5000), ship("b", 100)],
      500,
    );

    expect(positions.a.x).toBe(250);
    expect(positions.b.x).toBe(250);
    expect(positions.huge.x).toBeGreaterThan(0);
  });

  it("centres ships vertically within their row", () => {
    const positions = arrangeClassic(
      [ship("a", 100, 10), ship("b", 100, 40)],
      500,
    );

    expect(positions.a.y).toBe(positions.b.y);
  });
});

describe("boundsOf", () => {
  it("covers every ship, whatever its coordinates", () => {
    const bounds = boundsOf([ship("a", 10, 10), ship("b", 10, 10)], {
      a: { x: -100, y: -50 },
      b: { x: 100, y: 50 },
    });

    expect(bounds.minX).toBeLessThan(-105);
    expect(bounds.minY).toBeLessThan(-55);
    expect(bounds.width).toBeGreaterThan(210);
    expect(bounds.height).toBeGreaterThan(110);
  });

  it("includes the room for a label", () => {
    const plain = boundsOf([ship("a")], { a: { x: 0, y: 0 } });
    const labelled = boundsOf([ship("a", 100, 20, 30)], { a: { x: 0, y: 0 } });

    expect(labelled.width).toBe(plain.width + 30);
    expect(labelled.minX).toBe(plain.minX - 30);
  });

  it("is empty without ships", () => {
    expect(boundsOf([], {})).toEqual({
      minX: 0,
      minY: 0,
      width: 0,
      height: 0,
    });
  });
});

describe("autoScreenHeightFactor", () => {
  const screen = { width: 400, height: 225 };
  const columnHeight = (factor: number) => screen.height * factor - 30;

  it("never squeezes a small fleet below one screen", () => {
    expect(autoScreenHeightFactor([ship("a")], screen, columnHeight)).toBe(1);
  });

  it("grows with a large fleet", () => {
    const ships = Array.from({ length: 200 }, (_, index) => ship(`${index}`));

    expect(autoScreenHeightFactor(ships, screen, columnHeight)).toBeGreaterThan(
      1,
    );
  });

  it("falls back to one screen before the screen is known", () => {
    expect(
      autoScreenHeightFactor(
        [ship("a")],
        { width: 0, height: 0 },
        columnHeight,
      ),
    ).toBe(1);
  });
});

describe("gridCellFor", () => {
  it("uses a coarser cell when zoomed out", () => {
    expect(gridCellFor(4)).toBe(10);
    expect(gridCellFor(1)).toBe(50);
  });

  it("uses a finer cell when zoomed in", () => {
    expect(gridCellFor(40)).toBe(1);
  });
});

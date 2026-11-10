import { describe, expect, it } from "vitest";
import {
  arrangeClassic,
  arrangeColumns,
  arrangeFree,
  arrangePacked,
  snapToGrid,
  autoScreenHeightFactor,
  boundsOf,
  gridCellFor,
  groupHeadings,
  withHeadings,
  withRowWidth,
  type FleetchartLayoutShip,
  type FleetchartPositions,
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

describe("arrangePacked", () => {
  const overlaps = (
    ships: FleetchartLayoutShip[],
    positions: ReturnType<typeof arrangePacked>,
  ) =>
    ships.some((a, index) =>
      ships.slice(index + 1).some((b) => {
        const dx = Math.abs(positions[a.id].x - positions[b.id].x);
        const dy = Math.abs(positions[a.id].y - positions[b.id].y);

        return dx < (a.width + b.width) / 2 && dy < (a.height + b.height) / 2;
      }),
    );

  const mixed = [
    ship("large", 300, 100),
    ship("tall", 40, 200),
    ...Array.from({ length: 30 }, (_, index) =>
      ship(`small-${index}`, 20 + (index % 5) * 10, 10 + (index % 4) * 8),
    ),
  ];

  it("places every ship without any overlapping", () => {
    const positions = arrangePacked(mixed, 16 / 9);

    expect(Object.keys(positions)).toHaveLength(mixed.length);
    expect(overlaps(mixed, positions)).toBe(false);
  });

  it("takes less area than columns do", () => {
    const area = (positions: ReturnType<typeof arrangePacked>) => {
      const { width, height } = boundsOf(mixed, positions);

      return width * height;
    };

    expect(area(arrangePacked(mixed, 16 / 9))).toBeLessThan(
      area(arrangeColumns(mixed, 250)),
    );
  });

  it("puts small ships in the space beside a large one", () => {
    const ships = [
      ship("large", 300, 100),
      ship("wide", 400, 10),
      ship("small-a", 40, 20),
      ship("small-b", 40, 20),
    ];
    const positions = arrangePacked(ships, 1);

    expect(positions["small-a"].y).toBeLessThan(positions.large.y + 50);
    expect(positions["small-a"].x).toBeGreaterThan(positions.large.x + 150);
  });

  it("follows the screen's proportions", () => {
    const shape = (ratio: number) => {
      const { width, height } = boundsOf(mixed, arrangePacked(mixed, ratio));

      return width / height;
    };

    expect(shape(3)).toBeGreaterThan(shape(0.5));
  });

  it("keeps groups apart and without overlaps", () => {
    const grouped = mixed.map((entry, index) => ({
      ...entry,
      group: index % 2 ? "one" : "two",
    }));
    const positions = arrangePacked(grouped, 16 / 9);
    const area = (group: string) =>
      boundsOf(
        grouped.filter((entry) => entry.group === group),
        positions,
      );
    const one = area("one");
    const two = area("two");

    expect(overlaps(grouped, positions)).toBe(false);
    expect(
      one.minX < two.minX + two.width &&
        two.minX < one.minX + one.width &&
        one.minY < two.minY + two.height &&
        two.minY < one.minY + one.height,
    ).toBe(false);
  });

  it("sets a small group beside a large one rather than under it", () => {
    const grouped = [
      { ...ship("large", 100, 800), group: "large" },
      { ...ship("small", 100, 40), group: "small" },
    ];
    const positions = arrangePacked(grouped, 16 / 9);

    expect(positions.small.x).toBeGreaterThan(positions.large.x);
    expect(positions.small.y).toBeLessThan(positions.large.y);
  });

  it("is empty without ships", () => {
    expect(arrangePacked([], 16 / 9)).toEqual({});
  });
});

describe("arrangeFree", () => {
  it("leaves placed ships exactly where they were put", () => {
    expect(arrangeFree([ship("a")], { a: { x: -40, y: 900 } }, 500).a).toEqual({
      x: -40,
      y: 900,
    });
  });

  it("keeps unplaced ships clear of the placed ones", () => {
    const positions = arrangeFree(
      [ship("a"), ship("new")],
      { a: { x: 0, y: 0 } },
      500,
    );

    expect(positions.new.y - 10).toBeGreaterThan(positions.a.y + 10);
  });

  it("copes with nothing placed yet", () => {
    expect(arrangeFree([ship("a")], {}, 500).a).toBeDefined();
  });
});

describe("snapToGrid", () => {
  it("lands the ship's top left corner on the grid", () => {
    const size = { width: 30, height: 12 };
    const { x, y } = snapToGrid({ x: 27, y: 18 }, size, 10);

    expect((x - 15) % 10).toBe(0);
    expect((y - 6) % 10).toBe(0);
  });
});

describe("columns aligned for a heading", () => {
  it("starts every ship at the column's left edge", () => {
    const positions = arrangeColumns([ship("a", 40), ship("b", 100)], 500, {
      leftAligned: true,
    });

    expect(positions.a.x - 20).toBe(positions.b.x - 50);
  });
});

describe("columns facing up or down", () => {
  it("centres ships in their column", () => {
    const positions = arrangeColumns([ship("a", 40), ship("b", 100)], 500, {
      centred: true,
    });

    expect(positions.a.x).toBe(positions.b.x);
  });
});

describe("groups", () => {
  const grouped = (id: string, group: string) => ({ ...ship(id), group });

  it("starts a new column for a new group, even with room left", () => {
    const positions = arrangeColumns(
      [grouped("a", "one"), grouped("b", "one"), grouped("c", "two")],
      500,
    );

    expect(positions.a.x).toBe(positions.b.x);
    expect(positions.c.x).toBeGreaterThan(positions.a.x);
  });

  it("starts a new row for a new group, even with room left", () => {
    const positions = arrangeClassic(
      [grouped("a", "one"), grouped("b", "one"), grouped("c", "two")],
      5000,
    );

    expect(positions.a.y).toBe(positions.b.y);
    expect(positions.c.y).toBeGreaterThan(positions.a.y);
  });

  it("widens a column to fit its heading", () => {
    const positions = arrangeColumns(
      [{ ...grouped("a", "one"), headingWidth: 400 }, grouped("b", "two")],
      500,
    );

    expect(positions.b.x - 50).toBeGreaterThan(400);
  });

  it("keeps a wide heading inside a right-aligned column", () => {
    const ships = [
      { ...grouped("a", "one"), headingWidth: 400 },
      grouped("b", "two"),
    ];
    const positions = arrangeColumns(ships, 500);
    const [heading] = groupHeadings(ships, positions, "right");

    expect(heading.x).toBeGreaterThanOrEqual(0);
    expect(heading.x + 400).toBeLessThanOrEqual(positions.b.x - 50);
  });

  it("keeps a wide heading inside a centred column", () => {
    const ships = [
      { ...grouped("a", "one"), headingWidth: 400 },
      grouped("b", "two"),
    ];
    const positions = arrangeColumns(ships, 500, { centred: true });
    const [heading] = groupHeadings(ships, positions, "centre");

    expect(heading.x).toBeGreaterThanOrEqual(0);
    expect(heading.x + 400).toBeLessThanOrEqual(positions.b.x - 50);
  });

  it("starts a packed heading at its block, which has room for it", () => {
    const ships = [{ ...grouped("a", "one"), headingWidth: 400 }];
    const positions = arrangePacked(ships, 16 / 9);
    const [heading] = groupHeadings(ships, positions);

    expect(heading.x).toBe(boundsOf(ships, positions).minX);
  });

  it("widens the bounds to a heading reaching past the ships", () => {
    const bounds = withHeadings({ minX: 0, minY: 0, width: 100, height: 50 }, [
      { title: "long", x: -20, y: 0, width: 300 },
    ]);

    expect(bounds.minX).toBe(-20);
    expect(bounds.width).toBe(300);
  });

  it("places one heading per group, clear above its ships", () => {
    const ships = [
      grouped("a", "one"),
      grouped("b", "one"),
      grouped("c", "two"),
    ];
    const positions = arrangeClassic(ships, 5000);
    const headings = groupHeadings(ships, positions);

    expect(headings.map((heading) => heading.title)).toEqual(["one", "two"]);
    expect(headings[1].y).toBeLessThan(positions.c.y - 10);
    expect(headings[1].y).toBeGreaterThan(positions.a.y + 10);
  });

  it("counts a heading as part of the area to draw", () => {
    const ships = [grouped("a", "one")];
    const positions = arrangeColumns(ships, 500);
    const [heading] = groupHeadings(ships, positions);

    expect(boundsOf(ships, positions).minY).toBeLessThan(heading.y);
  });

  it("makes room for a taller heading in every layout", () => {
    const tall = (id: string) => ({ ...grouped(id, "one"), headingRoom: 100 });
    const gapUnder = (
      arrange: (ships: FleetchartLayoutShip[]) => FleetchartPositions,
    ) => {
      const plain = arrange([grouped("a", "one")]);
      const roomy = arrange([tall("a")]);
      const [heading] = groupHeadings([tall("a")], roomy);

      expect(heading.y).toBe(boundsOf([tall("a")], roomy).minY + 50);

      return roomy.a.y - plain.a.y;
    };

    expect(gapUnder((ships) => arrangeColumns(ships, 500))).toBe(85);
    expect(gapUnder((ships) => arrangeClassic(ships, 500))).toBe(85);
    expect(gapUnder((ships) => arrangePacked(ships, 1))).toBe(85);
  });

  it("has no headings without groups", () => {
    expect(groupHeadings([ship("a")], { a: { x: 0, y: 0 } })).toEqual([]);
  });
});

describe("spacing", () => {
  it("moves ships apart with more padding", () => {
    const tight = arrangeClassic(
      [
        { ...ship("a"), padding: 2 },
        { ...ship("b"), padding: 2 },
      ],
      5000,
    );
    const wide = arrangeClassic(
      [
        { ...ship("a"), padding: 20 },
        { ...ship("b"), padding: 20 },
      ],
      5000,
    );

    expect(wide.b.x - wide.a.x).toBeGreaterThan(tight.b.x - tight.a.x);
  });
});

describe("withRowWidth", () => {
  it("keeps the space beside a centred row", () => {
    expect(
      withRowWidth({ minX: 100, minY: 0, width: 50, height: 10 }, 400),
    ).toEqual({ minX: 0, minY: 0, width: 400, height: 10 });
  });

  it("does not cut off a row wider than the screen", () => {
    expect(
      withRowWidth({ minX: 0, minY: 0, width: 900, height: 10 }, 400).width,
    ).toBe(900);
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

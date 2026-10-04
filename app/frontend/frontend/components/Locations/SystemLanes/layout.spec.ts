import { describe, expect, it } from "vitest";
import { LocationKindEnum, type LocationJumpPoint } from "@/services/fyApi";
import { jumpConnections, jumpLaneLayout, unjoinedJumpPoints } from "./layout";

const jumpPoint = (
  systemId: string,
  destinationName: string,
  destinationSystemId: string | null,
): LocationJumpPoint => ({
  location: {
    id: `${systemId}-${destinationName}`,
    name: `${systemId} - ${destinationName} Jump Point`,
    slug: `${systemId}-${destinationName}`.toLowerCase(),
    kind: LocationKindEnum.JUMP_POINT,
    parentName: null,
  },
  systemId,
  destinationName,
  destinationSystemId,
  temporary: false,
});

const both = (a: string, b: string) => [jumpPoint(a, b, b), jumpPoint(b, a, a)];

const columnOf = (
  layout: ReturnType<typeof jumpLaneLayout>,
  a: string,
  b: string,
) =>
  layout.lanes.find((lane) => lane.connection.key === [a, b].sort().join(":"))
    ?.column;

describe("jumpConnections", () => {
  it("joins the two ends of a tunnel into one connection", () => {
    const connections = jumpConnections(["nyx", "pyro"], both("nyx", "pyro"));

    expect(connections).toHaveLength(1);
    expect(connections[0].ends.nyx?.destinationName).toBe("pyro");
    expect(connections[0].ends.pyro?.destinationName).toBe("nyx");
  });

  it("keeps a connection the data has only one end of", () => {
    const connections = jumpConnections(
      ["nyx", "pyro"],
      [jumpPoint("nyx", "pyro", "pyro")],
    );

    expect(connections).toHaveLength(1);
    expect(connections[0].ends.pyro).toBeUndefined();
  });

  it("leaves out jump points to systems that are not listed", () => {
    const connections = jumpConnections(
      ["stanton"],
      [jumpPoint("stanton", "Terra", null)],
    );

    expect(connections).toEqual([]);
  });
});

describe("unjoinedJumpPoints", () => {
  it("keeps what no line ends at: the way off the page and a second way across", () => {
    const systems = ["stanton", "pyro"];
    const jumpPoints = [
      jumpPoint("stanton", "Terra", null),
      jumpPoint("stanton", "pyro", "pyro"),
      {
        ...jumpPoint("stanton", "pyro", "pyro"),
        location: {
          ...jumpPoint("stanton", "pyro", "pyro").location,
          id: "second",
        },
      },
      jumpPoint("pyro", "stanton", "stanton"),
    ];

    const unjoined = unjoinedJumpPoints(
      jumpPoints,
      jumpConnections(systems, jumpPoints),
    );

    expect(unjoined.stanton.map((point) => point.location.id)).toEqual([
      "stanton-Terra",
      "second",
    ]);
    expect(unjoined.pyro).toBeUndefined();
  });
});

describe("jumpLaneLayout", () => {
  it("never lets two lines that meet at one card share a column", () => {
    const systems = ["nyx", "pyro", "stanton"];
    const layout = jumpLaneLayout(
      systems,
      jumpConnections(systems, [
        ...both("nyx", "pyro"),
        ...both("pyro", "stanton"),
      ]),
    );

    expect(columnOf(layout, "nyx", "pyro")).not.toBe(
      columnOf(layout, "pyro", "stanton"),
    );
  });

  it("keeps the given order when every order is as good", () => {
    const systems = ["nyx", "pyro", "stanton"];
    const layout = jumpLaneLayout(
      systems,
      jumpConnections(systems, [
        ...both("nyx", "pyro"),
        ...both("pyro", "stanton"),
        ...both("nyx", "stanton"),
      ]),
    );

    expect(layout.order).toEqual(systems);
    expect(layout.columns).toBe(3);
  });

  it("orders the systems so connected ones sit together", () => {
    const systems = ["castra", "magnus", "nyx", "pyro", "stanton", "terra"];
    const layout = jumpLaneLayout(
      systems,
      jumpConnections(systems, [
        ...both("nyx", "pyro"),
        ...both("pyro", "stanton"),
        ...both("stanton", "terra"),
        ...both("castra", "nyx"),
        ...both("nyx", "stanton"),
        ...both("pyro", "terra"),
        ...both("castra", "pyro"),
        ...both("magnus", "stanton"),
        ...both("magnus", "terra"),
      ]),
    );

    expect(layout.order).toEqual([
      "castra",
      "nyx",
      "pyro",
      "stanton",
      "terra",
      "magnus",
    ]);
    expect(layout.columns).toBe(5);
    expect(
      Math.max(...layout.lanes.map((lane) => lane.lower - lane.upper)),
    ).toBe(2);
  });
});

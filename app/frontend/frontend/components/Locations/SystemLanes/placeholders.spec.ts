import { describe, expect, it } from "vitest";
import { LocationKindEnum, type LocationJumpPoint } from "@/services/fyApi";
import {
  PLACEHOLDER_SYSTEMS,
  plannedConnections,
  pointIntoPlaceholders,
} from "./placeholders";

const terra = PLACEHOLDER_SYSTEMS.find(
  (placeholder) => placeholder.id === "placeholder-terra",
);

const jumpPoint = (
  destinationName: string,
  destinationSystemId: string | null,
): LocationJumpPoint => ({
  location: {
    id: `stanton-${destinationName}`,
    name: `Stanton - ${destinationName} Jump Point`,
    slug: `stanton-${destinationName}`.toLowerCase(),
    kind: LocationKindEnum.JUMP_POINT,
    parentName: null,
  },
  systemId: "stanton",
  destinationName,
  destinationSystemId,
});

describe("pointIntoPlaceholders", () => {
  it("points a jump point at the placeholder it names", () => {
    const [pointed] = pointIntoPlaceholders(
      [jumpPoint("Terra", null)],
      terra ? [terra] : [],
    );

    expect(pointed.destinationSystemId).toBe("placeholder-terra");
  });

  it("leaves a jump point to a listed system as it is", () => {
    const [pointed] = pointIntoPlaceholders(
      [jumpPoint("Pyro", "pyro")],
      terra ? [terra] : [],
    );

    expect(pointed.destinationSystemId).toBe("pyro");
  });
});

describe("plannedConnections", () => {
  it("joins the placeholder to the system it is announced to reach", () => {
    const connections = plannedConnections(
      new Map([
        ["castra", "placeholder-castra"],
        ["nyx", "nyx"],
      ]),
    );

    expect(connections.map((connection) => connection.systemIds)).toEqual([
      ["nyx", "placeholder-castra"],
    ]);
  });

  it("keeps the connection once the system it stood in for is listed", () => {
    const connections = plannedConnections(
      new Map([
        ["castra", "castra"],
        ["nyx", "nyx"],
      ]),
    );

    expect(connections.map((connection) => connection.systemIds)).toEqual([
      ["castra", "nyx"],
    ]);
  });

  it("draws nothing to a system that is not on the page", () => {
    expect(plannedConnections(new Map([["castra", "castra"]]))).toEqual([]);
  });
});

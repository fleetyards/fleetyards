import { describe, expect, it } from "vitest";
import type { FleetFleetchart } from "@/services/fyApi";
import { joinFleetchartShips, modelsOfShips } from "./fleetShips";

const model = (id: string) => ({
  id,
  name: id,
  slug: id,
  manufacturer: { name: "RSI", slug: "rsi" },
  metrics: {
    length: 10,
    beam: 5,
    height: 3,
    fleetchartOffsetLength: 10,
    fleetchartOffsetBeam: 5,
  },
});

const data: FleetFleetchart = {
  models: [model("aurora"), model("carrack")],
  modulePackages: [
    {
      id: "package",
      name: "Package",
    } as FleetFleetchart["modulePackages"][number],
  ],
  items: [
    { id: "1", modelId: "carrack", modulePackageId: "package" },
    { id: "2", modelId: "aurora", username: "kirk" },
    { id: "3", modelId: "carrack" },
    { id: "4", modelId: "missing" },
  ],
};

describe("joinFleetchartShips", () => {
  it("gives each ship its model and module package", () => {
    const ships = joinFleetchartShips(data);

    expect(ships.map((ship) => [ship.id, ship.model.id])).toEqual([
      ["1", "carrack"],
      ["2", "aurora"],
      ["3", "carrack"],
    ]);
    expect(ships[0].modulePackage?.id).toBe("package");
    expect(ships[1].username).toBe("kirk");
  });

  it("gives every ship a model of its own", () => {
    const [first, , third] = joinFleetchartShips(data);

    expect(first.model).not.toBe(third.model);
  });

  it("is empty before the response arrives", () => {
    expect(joinFleetchartShips(undefined)).toEqual([]);
  });
});

describe("modelsOfShips", () => {
  it("keeps one entry per model in the order its first ship came", () => {
    expect(
      modelsOfShips(joinFleetchartShips(data)).map((entry) => entry.id),
    ).toEqual(["carrack", "aurora"]);
  });
});

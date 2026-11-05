import { describe, expect, it } from "vitest";
import { OutfitHolderEnum } from "@/services/fyApi";
import {
  addStored,
  fitsInside,
  holderProblem,
  parseStoredQuery,
  setStoredQuantity,
  storeProblem,
  storedQuery,
  usedSpace,
} from "./dressingRoomStorage";

const PACK = {
  capacity: 1000,
  dimensions: { x: 0.64, y: 1, z: 0.45 },
};

const PEN = {
  volume: 0.00018,
  volumeDimensions: { x: 0.03, y: 0.03, z: 0.1 },
};

describe("the stored items in an address", () => {
  it("reads what each piece holds, with one as the default quantity", () => {
    expect(parseStoredQuery({ stored_backpack: "medpen*3,knife" })).toEqual({
      backpack: [
        { slug: "medpen", quantity: 3 },
        { slug: "knife", quantity: 1 },
      ],
    });
  });

  it("stacks a slug repeated by hand, within the limit", () => {
    expect(
      parseStoredQuery({ stored_backpack: "pen*2,pen*3,gun*999,gun" }).backpack,
    ).toEqual([
      { slug: "pen", quantity: 5 },
      { slug: "gun", quantity: 999 },
    ]);
  });

  it("does not trust a quantity it cannot read or the API would refuse", () => {
    expect(
      parseStoredQuery({ stored_legs: "a*x,b*0,c*-2,d*5000" }).legs,
    ).toEqual([
      { slug: "a", quantity: 1 },
      { slug: "b", quantity: 1 },
      { slug: "c", quantity: 1 },
      { slug: "d", quantity: 999 },
    ]);
  });

  it("writes back what it reads, and nothing for an empty piece", () => {
    const query = storedQuery({
      backpack: [
        { slug: "medpen", quantity: 3 },
        { slug: "knife", quantity: 1 },
      ],
      legs: [],
    });

    expect(query.stored_backpack).toBe("medpen*3,knife");
    expect(query.stored_legs).toBeUndefined();
  });
});

describe("changing what is stored", () => {
  it("stacks a second of the same item", () => {
    const once = addStored({}, OutfitHolderEnum.BACKPACK, "medpen");

    expect(
      addStored(once, OutfitHolderEnum.BACKPACK, "medpen").backpack,
    ).toEqual([{ slug: "medpen", quantity: 2 }]);
  });

  it("drops an item at zero", () => {
    const stored = { backpack: [{ slug: "medpen", quantity: 2 }] };

    expect(
      setStoredQuantity(stored, OutfitHolderEnum.BACKPACK, "medpen", 0)
        .backpack,
    ).toEqual([]);
  });
});

describe("what fits", () => {
  it("adds up volume in microSCU", () => {
    expect(usedSpace([{ slug: "medpen", quantity: 5 }], { medpen: PEN })).toBe(
      900,
    );
  });

  it("lets an item be turned to fit", () => {
    expect(
      fitsInside(PACK, { volumeDimensions: { x: 0.1, y: 0.95, z: 0.1 } }),
    ).toBe(true);
    expect(
      fitsInside(PACK, { volumeDimensions: { x: 0.1, y: 1.2, z: 0.1 } }),
    ).toBe(false);
  });

  it("says why one more would not go in", () => {
    expect(storeProblem(PACK, PEN, 0)).toBeUndefined();
    expect(storeProblem(PACK, PEN, 900)).toBe("noRoom");
    expect(storeProblem(PACK, { volume: null }, 0)).toBe("unmeasured");
    expect(
      storeProblem(
        PACK,
        { volume: 0.0001, volumeDimensions: { x: 2, y: 0.1, z: 0.1 } },
        0,
      ),
    ).toBe("tooLarge");
  });

  it("flags contents a worn piece can no longer hold", () => {
    const entries = [{ slug: "medpen", quantity: 6 }];

    expect(holderProblem(undefined, entries, { medpen: PEN })).toBe(
      "noStorage",
    );
    expect(holderProblem(PACK, entries, { medpen: PEN })).toBe("overCapacity");
    expect(holderProblem(PACK, [], { medpen: PEN })).toBeUndefined();
    expect(
      holderProblem(PACK, [{ slug: "prop", quantity: 1 }], {
        prop: { volume: null },
      }),
    ).toBe("unmeasured");
  });
});

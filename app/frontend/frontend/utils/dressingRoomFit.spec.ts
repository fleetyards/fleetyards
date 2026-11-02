import { describe, expect, it } from "vitest";
import { OutfitSlotEnum } from "@/services/fyApi";
import { type FitItem, fitsSlot, slotFit } from "./dressingRoomFit";

const armourPort = (name: string, type: string) => ({
  name,
  types: [{ type }],
  minSize: 1,
  maxSize: 1,
});

const undersuit: FitItem = {
  name: "CDS Undersuit",
  fit: {
    type: "Char_Armor_Undersuit",
    ports: [
      armourPort("Armor_Torso", "Char_Armor_Torso"),
      armourPort("Armor_Arms", "Char_Armor_Arms"),
      armourPort("Armor_Legs", "Char_Armor_Legs"),
      {
        name: "wep_stocked_3",
        types: [{ type: "WeaponPersonal", subTypes: ["Medium", "Large"] }],
        minSize: 2,
        maxSize: 5,
      },
    ],
  },
};

const flightSuit: FitItem = {
  name: "Flight Suit",
  fit: {
    type: "Char_Armor_Undersuit",
    ports: [armourPort("Armor_Helmet", "Char_Armor_Helmet")],
  },
};

const lightCore: FitItem = {
  name: "Light Core",
  fit: {
    type: "Char_Armor_Torso",
    ports: [
      {
        name: "backpack",
        types: [{ type: "Char_Armor_Backpack" }],
        minSize: 1,
        maxSize: 1,
        requiredTags: ["$backpack"],
      },
    ],
  },
};

const arms: FitItem = {
  name: "ADP Arms",
  size: "1",
  fit: { type: "Char_Armor_Arms" },
};

const backpack = (size: number, extra: Partial<FitItem["fit"]> = {}) => ({
  name: `Backpack ${size}`,
  size: String(size),
  fit: { type: "Char_Armor_Backpack", tags: ["backpack"], ...extra },
});

describe("slotFit", () => {
  it("leaves a slot open while nothing worn would offer its port", () => {
    expect(slotFit(OutfitSlotEnum.ARMS, {})).toEqual({ kind: "open" });
    expect(fitsSlot(slotFit(OutfitSlotEnum.ARMS, {}), arms)).toBe(true);
  });

  it("closes the arms on a flight suit without an arms port", () => {
    const fit = slotFit(OutfitSlotEnum.ARMS, {
      [OutfitSlotEnum.UNDERSUIT]: flightSuit,
    });

    expect(fit.kind).toBe("none");
    expect(fitsSlot(fit, arms)).toBe(false);
  });

  it("takes armour of the port's type on an undersuit with the port", () => {
    const fit = slotFit(OutfitSlotEnum.ARMS, {
      [OutfitSlotEnum.UNDERSUIT]: undersuit,
    });

    expect(fitsSlot(fit, arms)).toBe(true);
    expect(fitsSlot(fit, { ...arms, fit: { type: "Char_Armor_Legs" } })).toBe(
      false,
    );
  });

  it("holds a backpack to its core's size and tags", () => {
    const fit = slotFit(OutfitSlotEnum.BACKPACK, {
      [OutfitSlotEnum.TORSO]: lightCore,
    });

    expect(fitsSlot(fit, backpack(1))).toBe(true);
    expect(fitsSlot(fit, backpack(3))).toBe(false);
    expect(fitsSlot(fit, backpack(1, { tags: ["utility"] }))).toBe(false);
    expect(
      fitsSlot(
        fit,
        backpack(1, { requiredTags: ["CdsSuperheavyBackpack_01"] }),
      ),
    ).toBe(false);
  });

  it("takes a rifle on the back mount by its sub type and size", () => {
    const fit = slotFit(OutfitSlotEnum.PRIMARY, {
      [OutfitSlotEnum.UNDERSUIT]: undersuit,
    });
    const rifle = {
      name: "P4-AR",
      subType: "Medium",
      size: "2",
      fit: { type: "WeaponPersonal" },
    };

    expect(fitsSlot(fit, rifle)).toBe(true);
    expect(fitsSlot(fit, { ...rifle, subType: "Small", size: "1" })).toBe(
      false,
    );
  });
});

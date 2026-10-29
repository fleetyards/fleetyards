import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { HangarPledgeItemKindEnum } from "@/services/fyApi";
import Component from "./index.vue";

const carrack = {
  id: "carrack",
  name: "Carrack",
  slug: "carrack",
  onSale: true,
  pledgePrice: 600,
};

describe("HangarPlannerMeltContents", () => {
  it("lists the ships and items that melt with a pledge", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        ships: [
          { id: "named", name: "Endeavour", model: carrack },
          { id: "unnamed", model: carrack },
        ],
        items: [
          {
            id: "paint",
            name: "Carrack - Ghoul Paint",
            kind: HangarPledgeItemKindEnum.PAINT,
            quantity: 2,
          },
        ],
        unlisted: 1,
      },
    });

    const entries = wrapper.findAll("li").map((entry) => entry.text());

    expect(entries[0]).toBe("Endeavour (Carrack)");
    expect(entries[1]).toBe("Carrack");
    expect(entries[2]).toContain("Carrack - Ghoul Paint");
    expect(entries[2]).toContain("×2");
    expect(entries[3]).toContain("1 more item");
  });
});

import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import { craftedRouteQuery, useCraftedFromRoute } from "./useCraftedFromRoute";

const state = vi.hoisted(() => ({
  query: {} as Record<string, unknown>,
  recipe: undefined as unknown,
  placeholder: false,
}));

vi.mock("vue-router", async (importOriginal) => ({
  ...(await importOriginal<typeof import("vue-router")>()),
  useRoute: () => ({ query: state.query }),
}));

vi.mock("@/services/fyApi", async (importOriginal) => {
  const { ref } = await import("vue");

  return {
    ...(await importOriginal<typeof import("@/services/fyApi")>()),
    useBlueprint: () => ({
      data: ref(state.recipe),
      isPlaceholderData: ref(state.placeholder),
    }),
  };
});

const recipe = (craftableId: string) => ({
  slug: "bulwark-bp",
  craftable: { id: craftableId },
  costSlots: [
    {
      position: 1,
      modifiers: [
        {
          propertyKey: "gpp_shield_maxhealth",
          startQuality: 0,
          endQuality: 1000,
          modifierAtStart: 0.9,
          modifierAtEnd: 1.1,
        },
      ],
    },
  ],
});

const bulwark = { id: "bulwark", typeData: { maxHealth: 1000 } };

const craft = (record: typeof bulwark, factors: Map<string, number>) => ({
  ...record,
  typeData: {
    maxHealth:
      record.typeData.maxHealth * (factors.get("gpp_shield_maxhealth") ?? 1),
  },
});

describe("craftedRouteQuery", () => {
  it("writes the recipe and the grades in slot order", () => {
    expect(
      craftedRouteQuery({
        blueprint: { id: "bp-1", name: "Bulwark", slug: "bulwark-bp" },
        qualities: { 2: 500, 1: 750 },
      }),
    ).toEqual({ crafted: "bulwark-bp", grades: "1:750,2:500" });
  });
});

describe("useCraftedFromRoute", () => {
  it("applies the recipe and grades the address names", () => {
    state.query = { crafted: "bulwark-bp", grades: "1:1000" };
    state.recipe = recipe("bulwark");

    const { crafted, gradesLabel } = useCraftedFromRoute(ref(bulwark), craft);

    expect(crafted.value?.typeData.maxHealth).toBeCloseTo(1100);
    expect(gradesLabel.value).toBe("1000");
  });

  // A recipe for something else says nothing about this part.
  it("ignores a recipe that makes something else", () => {
    state.query = { crafted: "bulwark-bp", grades: "1:1000" };
    state.recipe = recipe("another-part");

    const { crafted } = useCraftedFromRoute(ref(bulwark), craft);

    expect(crafted.value).toBeUndefined();
  });

  it("drops a grade outside 0 to 1000", () => {
    state.query = { crafted: "bulwark-bp", grades: "1:5000" };
    state.recipe = recipe("bulwark");

    const { crafted } = useCraftedFromRoute(ref(bulwark), craft);

    // The slot reads as the neutral grade, the catalogue's own figure.
    expect(crafted.value?.typeData.maxHealth).toBeCloseTo(1000);
  });

  // The app keeps a query's last answer while the next loads, so the recipe
  // can still be there once the address no longer names one.
  it("shows the stock part once the address names no recipe", () => {
    state.query = {};
    state.recipe = recipe("bulwark");

    const { crafted } = useCraftedFromRoute(ref(bulwark), craft);

    expect(crafted.value).toBeUndefined();
  });

  it("ignores a recipe kept from the last query", () => {
    state.query = { crafted: "other-bp", grades: "1:1000" };
    state.recipe = recipe("bulwark");
    state.placeholder = true;

    const { crafted } = useCraftedFromRoute(ref(bulwark), craft);

    expect(crafted.value).toBeUndefined();

    state.placeholder = false;
  });
});

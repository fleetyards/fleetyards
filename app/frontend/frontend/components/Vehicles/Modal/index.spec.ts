import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import { type Vehicle, BoughtViaEnum } from "@/services/fyApi";

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useVehicleBoughtViaFilters: () => ({
    data: ref([
      { label: "Pledge Store", value: "pledge_store", category: "boughtVia" },
      { label: "In-Game", value: "ingame", category: "boughtVia" },
    ]),
  }),
  modelPaints: vi.fn(),
}));

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({
    useUpdateMutation: () => ({ mutateAsync: vi.fn(), isPending: ref(false) }),
  }),
}));

const vehicle = (ingameOnly: boolean): Vehicle =>
  ({
    id: "vehicle-1",
    boughtVia: BoughtViaEnum.PLEDGE_STORE,
    model: {
      id: "model-1",
      name: "ATLS IKTI",
      slug: "argo-atls-ikti",
      ingameOnly,
    },
  }) as Vehicle;

const boughtViaOptions = async (ingameOnly: boolean) => {
  const wrapper = await mountWithDefaults(Component, {
    props: { vehicle: vehicle(ingameOnly), wishlist: false },
  });

  return wrapper
    .findAllComponents({ name: "BaseSelect" })
    .find((select) => select.props("name") === "boughtVia")
    ?.props("options") as { value: string }[];
};

describe("the way a ship was bought", () => {
  it("offers only in-game for a ship the pledge store never sells", async () => {
    expect(
      (await boughtViaOptions(true)).map((option) => option.value),
    ).toEqual(["ingame"]);
  });

  it("offers both for a pledge ship", async () => {
    expect(
      (await boughtViaOptions(false)).map((option) => option.value),
    ).toEqual(["pledge_store", "ingame"]);
  });
});

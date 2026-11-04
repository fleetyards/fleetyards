import { beforeEach, describe, expect, it, vi } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { useFleetchartCatalogueShips } from "./useFleetchartCatalogueShips";
import { useFleetchartStore } from "@/shared/stores/fleetchart";

const lastParams = ref<{ q: { idIn: string[] } }>();

vi.mock("@/services/fyApi", () => ({
  useModels: (params: { value: { q: { idIn: string[] } } }) => {
    watchEffect(() => {
      lastParams.value = params.value;
    });

    return { data: ref({ items: [{ id: "hornet", slug: "hornet" }] }) };
  },
}));

const place = (x: number) => {
  useFleetchartStore().updatePlacements({
    namespace: "hangar",
    placements: {
      owned: { x: 0, y: 0 },
      tried: { x, y: 0, modelId: "hornet" },
    },
  });
};

describe("useFleetchartCatalogueShips", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("draws the placed ships as not owned, and asks for their models", async () => {
    place(1);

    const entries = useFleetchartCatalogueShips("hangar", true);

    await nextTick();

    expect(entries.value).toEqual([
      { id: "tried", slug: "hornet", notOwned: true },
    ]);
    expect(lastParams.value?.q.idIn).toEqual(["hornet"]);
  });

  it("keeps the same list when a ship only moved", () => {
    place(1);

    const entries = useFleetchartCatalogueShips("hangar", true);
    const before = entries.value;

    place(2);

    expect(entries.value).toBe(before);
  });

  it("holds nothing while no free arrangement is showing", () => {
    place(1);

    expect(useFleetchartCatalogueShips("hangar", false).value).toEqual([]);
  });
});

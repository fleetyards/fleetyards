import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { QueryClient, VueQueryPlugin } from "@tanstack/vue-query";
import {
  getHangarAllInventoryStockQueryKey,
  getFleetAllInventoryStockQueryKey,
} from "@/services/fyApi";

let refresh: (() => unknown) | undefined;

vi.mock("@/frontend/composables/useInventoryUpdates", () => ({
  useInventoryUpdates: (onChange: () => unknown) => {
    refresh = onChange;
  },
}));

const { useMaterialStockUpdates } = await import("./useMaterialStock");

const render = () => {
  const queryClient = new QueryClient();
  const invalidate = vi.spyOn(queryClient, "invalidateQueries");

  mount(
    defineComponent({
      setup() {
        useMaterialStockUpdates();

        return () => h("div");
      },
    }),
    { global: { plugins: [[VueQueryPlugin, { queryClient }]] } },
  );

  return { invalidate };
};

// The predicate is written by hand against the shapes orval generates, and the
// two share no prefix -- the fleet's slug sits in the middle of its own. Asked
// of the generated key builders rather than of literals, so a key layout that
// changes under us fails here instead of quietly leaving held-material rows
// stale on the blueprint page.
describe("useMaterialStockUpdates", () => {
  const predicateFrom = (invalidate: ReturnType<typeof vi.spyOn>) => {
    refresh?.();

    const [options] = invalidate.mock.calls.at(-1) ?? [];

    return (options as { predicate: (query: unknown) => boolean }).predicate;
  };

  it("invalidates the hangar stock query", () => {
    const { invalidate } = render();

    expect(
      predicateFrom(invalidate)({
        queryKey: getHangarAllInventoryStockQueryKey(),
      }),
    ).toBe(true);
  });

  it("invalidates a fleet's stock query", () => {
    const { invalidate } = render();

    expect(
      predicateFrom(invalidate)({
        queryKey: getFleetAllInventoryStockQueryKey("acme"),
      }),
    ).toBe(true);
  });

  it("leaves other queries alone", () => {
    const { invalidate } = render();
    const predicate = predicateFrom(invalidate);

    expect(predicate({ queryKey: ["fleets", "acme", "members"] })).toBe(false);
    expect(predicate({ queryKey: ["hangar", "vehicles"] })).toBe(false);
    expect(predicate({ queryKey: ["blueprints"] })).toBe(false);
  });
});

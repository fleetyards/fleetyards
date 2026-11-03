import { afterEach, describe, expect, it, vi } from "vitest";
import { effectScope, type EffectScope } from "vue";
import { flushPromises } from "@vue/test-utils";
import { useCompareCatalogue } from "./useCompareCatalogue";

const slugs = ref<string[]>([]);
const replace = vi.fn((next: string[]) => {
  slugs.value = next;
});

vi.mock("@/frontend/composables/useCompareSet", () => ({
  useCompareSet: () => ({ slugs, replace }),
}));

type Item = { slug: string; name: string; category?: string };

const catalogue: Record<string, Item> = {
  "shield-a": { slug: "shield-a", name: "Shield A", category: "shield" },
  "shield-b": { slug: "shield-b", name: "Shield B", category: "shield" },
  "drive-a": { slug: "drive-a", name: "Drive A", category: "drive" },
  loose: { slug: "loose", name: "Loose" },
};

// Each in its own scope, stopped after the test: the slugs are shared, and a
// previous test's watchers would otherwise go on pruning them.
let scope: EffectScope | undefined;

afterEach(() => {
  scope?.stop();
  scope = undefined;
});

const setup = () => {
  scope = effectScope();

  return scope.run(() =>
    useCompareCatalogue({
      queryKey: "components",
      fetchItem: async (slug: string) => catalogue[slug],
      categoryOf: (item: Item) =>
        item.category
          ? { key: item.category, label: item.category, query: {} }
          : undefined,
    }),
  )!;
};

describe("useCompareCatalogue", () => {
  it("keeps the category of the first item the link names", async () => {
    slugs.value = ["drive-a", "shield-a", "shield-b"];
    replace.mockClear();

    const { items, category, dropped } = setup();
    await flushPromises();

    expect(category.value?.key).toBe("drive");
    expect(items.value.map((item) => item.slug)).toEqual(["drive-a"]);
    expect(dropped.value).toEqual(["Shield A", "Shield B"]);
    expect(replace).toHaveBeenCalledWith(["drive-a"]);
  });

  it("leaves a set of one category alone", async () => {
    slugs.value = ["shield-a", "shield-b"];
    replace.mockClear();

    const { items, dropped } = setup();
    await flushPromises();

    expect(items.value).toHaveLength(2);
    expect(dropped.value).toEqual([]);
    expect(replace).not.toHaveBeenCalled();
  });

  it("takes the lock from the first item that has a category", async () => {
    slugs.value = ["loose", "shield-a", "drive-a"];
    replace.mockClear();

    const { category, items } = setup();
    await flushPromises();

    expect(category.value?.key).toBe("shield");
    expect(items.value.map((item) => item.slug)).toEqual(["shield-a"]);
  });

  it("ends the notice once the set changes again", async () => {
    slugs.value = ["drive-a", "shield-a"];

    const { dropped } = setup();
    await flushPromises();
    expect(dropped.value).toEqual(["Shield A"]);

    slugs.value = [];
    await flushPromises();

    expect(dropped.value).toEqual([]);
  });
});

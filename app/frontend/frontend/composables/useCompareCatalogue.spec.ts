import { describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { useCompareCatalogue } from "./useCompareCatalogue";

const slugs = ref<string[]>([]);
const replace = vi.fn((next: string[]) => {
  slugs.value = next;
});

vi.mock("@/frontend/composables/useCompareSet", () => ({
  useCompareSet: () => ({ slugs, replace }),
}));

type Item = { slug: string; name: string; category: string };

const catalogue: Record<string, Item> = {
  "shield-a": { slug: "shield-a", name: "Shield A", category: "shield" },
  "shield-b": { slug: "shield-b", name: "Shield B", category: "shield" },
  "drive-a": { slug: "drive-a", name: "Drive A", category: "drive" },
};

const setup = () =>
  useCompareCatalogue({
    queryKey: "components",
    fetchItem: async (slug: string) => catalogue[slug],
    categoryOf: (item: Item) => ({
      key: item.category,
      label: item.category,
      query: {},
    }),
  });

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
});

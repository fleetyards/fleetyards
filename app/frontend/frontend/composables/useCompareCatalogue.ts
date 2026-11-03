import type { CompareCategory } from "@/frontend/components/Compare/category";
import { useCompareItems } from "@/frontend/composables/useCompareItems";
import { useCompareSet } from "@/frontend/composables/useCompareSet";

type CatalogueItem = { slug: string; name: string };

// A compare page for one catalogue: the set in the URL, the items it names, and
// the one category they all share.
//
// The first item the link names decides the category. A link put together by
// hand can still mix them, and a column of shields beside a quantum drive is a
// table of empty cells, so the others are taken out of the set and named once
// in `dropped`.
export const useCompareCatalogue = <T extends CatalogueItem, Q>({
  queryKey,
  fetchItem,
  categoryOf,
}: {
  queryKey: string;
  fetchItem: (slug: string) => Promise<T>;
  categoryOf: (item: T) => CompareCategory<Q> | undefined;
}) => {
  const { slugs, replace } = useCompareSet(queryKey);

  const {
    items: loaded,
    loading,
    asyncStatus,
  } = useCompareItems<T>(() => slugs.value, fetchItem);

  // The first item that has a category at all: one without cannot set the
  // lock, or a link leading with it would let any mix through.
  const category = computed(() =>
    slugs.value
      .map((slug) => loaded.value.find((item) => item.slug === slug))
      .map((item) => (item ? categoryOf(item) : undefined))
      .find(Boolean),
  );

  const belongs = (item: T) =>
    !category.value || categoryOf(item)?.key === category.value.key;

  const items = computed(() => loaded.value.filter(belongs));

  const dropped = ref<string[]>([]);

  // The set the strays were removed from it to. The notice is about that
  // removal, so any later change to the set ends it.
  let prunedTo: string | undefined;

  watch(slugs, (current) => {
    if (prunedTo === undefined || current.join(",") === prunedTo) return;

    prunedTo = undefined;
    dropped.value = [];
  });

  watch(
    [loaded, loading],
    () => {
      if (loading.value) return;

      const strays = loaded.value.filter((item) => !belongs(item));
      if (!strays.length) return;

      dropped.value = strays.map((item) => item.name);

      const strayed = new Set(strays.map((item) => item.slug));
      const kept = slugs.value.filter((slug) => !strayed.has(slug));

      prunedTo = kept.join(",");
      replace(kept);
    },
    { immediate: true },
  );

  const remove = (slug: string) => {
    replace(slugs.value.filter((entry) => entry !== slug));
  };

  return {
    slugs,
    items,
    category,
    dropped,
    loading,
    asyncStatus,
    remove,
  };
};

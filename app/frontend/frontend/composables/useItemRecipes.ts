import { type FilterOption, useBlueprints } from "@/services/fyApi";

/**
 * The recipes that make one catalogue item. More than one can, so the crafting
 * step offers a choice where there is one; an item none makes cannot be
 * crafted at all.
 */
export const useItemRecipes = (
  itemId: MaybeRefOrGetter<string | undefined>,
) => {
  const { data, isPlaceholderData } = useBlueprints(
    computed(() => ({
      perPage: "10",
      q: { craftableIdEq: toValue(itemId) },
    })),
    {
      query: {
        enabled: computed(() => !!toValue(itemId)),
        refetchOnWindowFocus: false,
      },
    },
  );

  // Not the last item's recipes while this item's load: the app keeps a
  // query's previous answer as a placeholder, which would offer crafting for a
  // part no recipe makes.
  const recipes = computed(() =>
    toValue(itemId) && !isPlaceholderData.value ? data.value?.items || [] : [],
  );

  const recipeOptions = computed<FilterOption[]>(() =>
    recipes.value.map((recipe) => ({
      value: recipe.id,
      label: recipe.name || recipe.slug,
    })),
  );

  return { recipes, recipeOptions };
};

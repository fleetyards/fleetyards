import { type FilterOption, useBlueprints } from "@/services/fyApi";

/**
 * The recipes that make one catalogue item. More than one can, so the crafting
 * step offers a choice where there is one; an item none makes cannot be
 * crafted at all.
 */
export const useItemRecipes = (
  itemId: MaybeRefOrGetter<string | undefined>,
) => {
  const { data } = useBlueprints(
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

  const recipes = computed(() => data.value?.items || []);

  const recipeOptions = computed<FilterOption[]>(() =>
    recipes.value.map((recipe) => ({
      value: recipe.id,
      label: recipe.name || recipe.slug,
    })),
  );

  return { recipes, recipeOptions };
};

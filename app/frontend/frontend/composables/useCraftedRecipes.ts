import { useQueries } from "@tanstack/vue-query";
import type { MaybeRefOrGetter } from "vue";
import type {
  CraftedPart,
  useComponentFitting,
} from "@/frontend/composables/useComponentFitting";
import { getBlueprintQueryOptions } from "@/services/fyApi";

/**
 * Fetches the recipe of every crafted part in a fitting and hands it to the
 * fitting, which then reads those parts' figures as crafted. One request per
 * recipe, however many parts were crafted from it.
 */
export const useCraftedRecipes = (
  fitting: ReturnType<typeof useComponentFitting>,
  crafting: MaybeRefOrGetter<Record<string, CraftedPart> | undefined>,
) => {
  const slugs = computed(() => [
    ...new Set(
      Object.values(toValue(crafting) ?? {}).map((part) => part.blueprintSlug),
    ),
  ]);

  const queries = useQueries({
    queries: computed(() =>
      slugs.value.map((slug) => getBlueprintQueryOptions(slug)),
    ),
  });

  watch(
    () => queries.value.map((query) => query.data),
    (recipes) =>
      recipes.forEach((recipe) => {
        if (recipe) fitting.learnRecipe(recipe.id, recipe.costSlots ?? []);
      }),
    { immediate: true },
  );
};

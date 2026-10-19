import type { Ref } from "vue";
import type { LocationQuery } from "vue-router";
import { craftedGrades } from "@/frontend/components/Logistics/crafted";
import {
  type CraftedEffect,
  craftedFactors,
} from "@/frontend/components/Logistics/craftedRecord";
import { type InventoryCraftedRef, useBlueprint } from "@/services/fyApi";

/**
 * A crafted part's detail page is the catalogue's page with the part's recipe
 * and grades in the address: `?crafted=<recipe>&grades=1:750,2:500`. The
 * address carries them rather than any store, so the page can be linked, and
 * reloads as the same part.
 */
export const craftedRouteQuery = (crafted: InventoryCraftedRef) => ({
  crafted: crafted.blueprint.slug,
  grades: craftedGrades(
    crafted.qualities,
    (position, grade) => `${position}:${grade}`,
  ).join(","),
});

// A repeated key arrives as an array, which names no single recipe.
const single = (value: LocationQuery[string]) =>
  typeof value === "string" ? value : "";

const parseGrades = (value: string) =>
  Object.fromEntries(
    value
      .split(",")
      .map((pair) => pair.split(":").map(Number))
      .filter(
        ([position, grade]) =>
          Number.isInteger(position) && grade >= 0 && grade <= 1000,
      ),
  ) as Record<string, number>;

/**
 * The record as the recipe and grades in the address leave it, or undefined
 * where the address names none -- or names a recipe for something else.
 */
export const useCraftedFromRoute = <T extends { id: string }>(
  record: Ref<T | undefined>,
  craft: (record: T, factors: Map<string, CraftedEffect>) => T,
) => {
  const route = useRoute();

  const recipeSlug = computed(() => single(route.query.crafted));
  const qualities = computed(() => parseGrades(single(route.query.grades)));

  const { data: fetched, isPlaceholderData } = useBlueprint(recipeSlug, {
    query: {
      enabled: computed(() => !!recipeSlug.value),
      refetchOnWindowFocus: false,
    },
  });

  // The app keeps a query's last answer while the next one loads, so a page
  // left for its stock values would otherwise go on showing the recipe it had.
  const recipe = computed(() =>
    recipeSlug.value && !isPlaceholderData.value ? fetched.value : undefined,
  );

  const crafted = computed(() => {
    if (!record.value || !recipe.value) return undefined;
    if (recipe.value.craftable?.id !== record.value.id) return undefined;

    return craft(
      record.value,
      craftedFactors(recipe.value.costSlots || [], qualities.value),
    );
  });

  const gradesLabel = computed(() =>
    craftedGrades(qualities.value).join(" / "),
  );

  // The same page, as the catalogue lists the part.
  const stockRoute = computed(() => ({
    query: { ...route.query, crafted: undefined, grades: undefined },
  }));

  return { crafted, recipe, gradesLabel, stockRoute };
};

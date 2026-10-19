import type { Ref } from "vue";
import {
  type CraftedSelection,
  type PickedItem,
} from "@/frontend/components/Logistics/types";
import { useItemRecipes } from "@/frontend/composables/useItemRecipes";

type Options = {
  pickedItem: Ref<PickedItem | undefined>;
  // Only a deposit records how a part was crafted; a withdrawal takes it from
  // the lot it comes out of.
  isDeposit: Ref<boolean>;
  showStep: (step: "form" | "crafting") => void;
};

/**
 * Crafting as a step of a ledger form: the form says whether the part was
 * crafted and from what, and a page of its own takes the recipe and the grade
 * of material in each slot. The page edits a draft, which the form takes only
 * when it is applied.
 */
export const useCraftingStep = ({
  pickedItem,
  isDeposit,
  showStep,
}: Options) => {
  const crafted = ref<CraftedSelection | undefined>(undefined);
  const draft = ref<CraftedSelection>({ blueprintId: "", qualities: {} });
  const draftValid = ref(false);

  // Only a component or a piece of equipment from the catalogue is crafted.
  const craftableItemId = computed(() =>
    pickedItem.value?.type === "Component" ||
    pickedItem.value?.type === "Equipment"
      ? pickedItem.value.id
      : undefined,
  );

  const { recipes } = useItemRecipes(craftableItemId);

  // And only one some recipe makes.
  const craftable = computed(
    () => !!craftableItemId.value && recipes.value.length > 0,
  );

  const craftedRecipe = computed(() =>
    recipes.value.find((recipe) => recipe.id === crafted.value?.blueprintId),
  );

  // What the form shows of it: the recipe, and the grades in slot order.
  const craftedGrades = computed(() =>
    crafted.value
      ? Object.entries(crafted.value.qualities)
          .sort(([a], [b]) => Number(a) - Number(b))
          .map(([, grade]) => grade)
          .join(" · ")
      : undefined,
  );

  const openCrafting = () => {
    draft.value = crafted.value
      ? { ...crafted.value, qualities: { ...crafted.value.qualities } }
      : { blueprintId: recipes.value[0]?.id ?? "", qualities: {} };

    showStep("crafting");
  };

  const applyCrafting = () => {
    if (!draftValid.value) return;

    crafted.value = draft.value;
    showStep("form");
  };

  const clearCrafted = () => {
    crafted.value = undefined;
  };

  // A different item has a different recipe, if any.
  watch(
    () => pickedItem.value?.id,
    () => {
      if (isDeposit.value) crafted.value = undefined;
    },
  );

  return {
    crafted,
    draft,
    draftValid,
    craftable,
    craftedRecipe,
    craftedGrades,
    openCrafting,
    applyCrafting,
    clearCrafted,
  };
};

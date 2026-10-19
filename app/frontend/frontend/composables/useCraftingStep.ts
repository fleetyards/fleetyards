import type { Ref } from "vue";
import {
  type CraftedSelection,
  type PickedItem,
} from "@/frontend/components/Logistics/types";
import {
  craftedGrades,
  craftedQualities,
} from "@/frontend/components/Logistics/crafted";
import { useItemRecipes } from "@/frontend/composables/useItemRecipes";
import { useI18n } from "@/shared/composables/useI18n";

type Options = {
  pickedItem: Ref<PickedItem | undefined>;
  // Only a deposit records how a part was crafted; a withdrawal takes it from
  // the lot it comes out of.
  isDeposit: Ref<boolean>;
  showStep: (step: "form" | "crafting") => void;
};

/**
 * Crafting as a step of a ledger form: the item's field says whether the part
 * was crafted and with what grades, and a page of its own takes the recipe and
 * the grade of material in each slot. The page edits a draft, which the form takes only
 * when it is applied.
 */
export const useCraftingStep = ({
  pickedItem,
  isDeposit,
  showStep,
}: Options) => {
  const { t } = useI18n();

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

  // What the item's field shows of it: the grades, in slot order.
  // A request may name no grade at all, which reads as crafted and nothing
  // more.
  const craftedLabel = computed(() => {
    if (!crafted.value) return undefined;

    const grades = craftedGrades(craftedQualities(crafted.value));

    return grades.length
      ? t("labels.logistics.crafted.summary", { grades: grades.join(" / ") })
      : t("labels.logistics.crafted.lot");
  });

  const openCrafting = () => {
    draft.value = crafted.value
      ? { ...crafted.value, qualities: { ...crafted.value.qualities } }
      : { blueprintId: recipes.value[0]?.id ?? "", qualities: {} };

    showStep("crafting");
  };

  const applyCrafting = () => {
    if (!draftValid.value) return;

    // A slot typed into and cleared again is a slot left open, not a grade.
    crafted.value = {
      blueprintId: draft.value.blueprintId,
      qualities: craftedQualities(draft.value),
    };
    showStep("form");
  };

  const clearCrafted = () => {
    crafted.value = undefined;
    showStep("form");
  };

  // A different item has a different recipe, if any.
  watch(
    () => pickedItem.value?.id,
    () => {
      if (isDeposit.value) crafted.value = undefined;
    },
  );

  // A withdrawal takes its crafting from the lot it picks, never from what
  // was entered for a deposit before the switch.
  watch(isDeposit, () => {
    crafted.value = undefined;
  });

  return {
    crafted,
    draft,
    draftValid,
    craftable,
    craftedLabel,
    openCrafting,
    applyCrafting,
    clearCrafted,
  };
};

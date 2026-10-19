import type { Ref } from "vue";
import { type PickedItem } from "@/frontend/components/Logistics/types";
import { craftedGrades } from "@/frontend/components/Logistics/crafted";
import { type CraftedPart } from "@/frontend/composables/craftedComponent";
import { useItemRecipes } from "@/frontend/composables/useItemRecipes";
import { useI18n } from "@/shared/composables/useI18n";
import { BlueprintCraftableTypeEnum } from "@/services/fyApi";

type Options = {
  pickedItem: Ref<PickedItem | undefined>;
  // Only a deposit records how a part was crafted; a withdrawal takes it from
  // the lot it comes out of.
  isDeposit: Ref<boolean>;
  showStep: (step: "form" | "crafting") => void;
};

// What the embedded crafter hands its host, whose footer drives it.
type CrafterHandle = {
  apply: () => void;
  remove: () => void;
  canApply: boolean;
};

/**
 * Crafting as a step of a ledger form: the item's field says whether the part
 * was crafted and with what grades, and the shared crafter takes the modal's
 * body to choose them. The crafter holds its own draft and hands it over only
 * when the footer applies it. The step's crafter must carry
 * `ref="itemCrafter"`.
 */
export const useCraftingStep = ({
  pickedItem,
  isDeposit,
  showStep,
}: Options) => {
  const { t } = useI18n();

  const crafted = ref<CraftedPart | undefined>(undefined);

  const crafter = useTemplateRef<CrafterHandle>("itemCrafter");

  const canApply = computed(() => !!crafter.value?.canApply);

  // Only a component or a piece of equipment from the catalogue is crafted.
  const craftableItemId = computed(() =>
    pickedItem.value?.type === "Component" ||
    pickedItem.value?.type === "Equipment"
      ? pickedItem.value.id
      : undefined,
  );

  const craftableType = computed(() =>
    pickedItem.value?.type === "Equipment"
      ? BlueprintCraftableTypeEnum.EQUIPMENT
      : BlueprintCraftableTypeEnum.COMPONENT,
  );

  const { recipes } = useItemRecipes(craftableItemId);

  // And only one some recipe makes.
  const craftable = computed(
    () => !!craftableItemId.value && recipes.value.length > 0,
  );

  // What the item's field shows of it: the grades, in slot order. A request
  // may name no grade at all, which reads as crafted and nothing more. Where
  // more than one recipe makes the part, which one it was crafted from too:
  // the same grades read alike from either.
  const craftedLabel = computed(() => {
    if (!crafted.value) return undefined;

    const grades = craftedGrades(crafted.value.qualities);
    const summary = grades.length
      ? t("labels.logistics.crafted.summary", { grades: grades.join(" / ") })
      : t("labels.logistics.crafted.lot");
    const recipe = recipes.value.find(
      (entry) => entry.id === crafted.value?.blueprintId,
    );

    return recipes.value.length > 1 && recipe?.name
      ? `${summary} · ${recipe.name}`
      : summary;
  });

  const openCrafting = () => showStep("crafting");

  // The footer's buttons, which the crafter answers with its own events.
  const applyCrafting = () => crafter.value?.apply();
  const removeCrafting = () => crafter.value?.remove();

  const onCrafted = (part: CraftedPart) => {
    crafted.value = part;
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
    canApply,
    craftable,
    craftableType,
    craftedLabel,
    openCrafting,
    applyCrafting,
    removeCrafting,
    onCrafted,
    clearCrafted,
  };
};

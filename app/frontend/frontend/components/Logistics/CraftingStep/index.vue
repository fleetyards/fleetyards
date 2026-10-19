<script lang="ts">
export default {
  name: "LogisticsCraftingStep",
};
</script>

<script lang="ts" setup>
import BlueprintPreview from "@/frontend/components/Blueprints/Preview/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { NEUTRAL_QUALITY } from "@/frontend/composables/useQualityRamp";
import { useItemRecipes } from "@/frontend/composables/useItemRecipes";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type CraftedSelection,
  type PickedItem,
} from "@/frontend/components/Logistics/types";
import { type BlueprintCostSlot, useBlueprint } from "@/services/fyApi";

type Props = {
  // The part being deposited; only one some recipe makes reaches this step.
  item: PickedItem;
  // A request rather than a record: a slot left blank takes any grade.
  optional?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  optional: false,
});

// The draft the step edits. The form only takes it once it is applied, so
// backing out leaves the form's crafting as it was.
const draft = defineModel<CraftedSelection>({ required: true });

const emit = defineEmits<{
  valid: [valid: boolean];
}>();

const { t } = useI18n();

const { recipes, recipeOptions } = useItemRecipes(() => props.item.id);

const recipeId = computed({
  get: () => draft.value.blueprintId,
  set: (blueprintId?: string) => {
    if (!blueprintId || blueprintId === draft.value.blueprintId) return;

    // Another recipe has other slots, so the grades start over.
    draft.value = { blueprintId, qualities: {} };
  },
});

const recipeSlug = computed(
  () =>
    recipes.value.find((recipe) => recipe.id === recipeId.value)?.slug ?? "",
);

const { data: fetchedRecipe, isPlaceholderData } = useBlueprint(recipeSlug, {
  query: {
    enabled: computed(() => !!recipeSlug.value),
    refetchOnWindowFocus: false,
  },
});

// Not the last recipe's slots while another one loads.
const recipe = computed(() =>
  isPlaceholderData.value ? undefined : fetchedRecipe.value,
);

// Only a slot whose material moves a stat asks for a grade; the API asks for
// exactly these.
const gradedSlots = computed(() =>
  (recipe.value?.costSlots || []).filter((slot) => slot.modifiers?.length),
);

const slotLabel = (slot: BlueprintCostSlot) => {
  const material = (slot.options || [])
    .map((option) => option.commodity?.name || option.commodityKey)
    .filter(Boolean)
    .join(" / ");
  const name =
    slot.name ||
    t("labels.logistics.crafted.slot", { position: slot.position });

  return material ? `${name} · ${material}` : name;
};

const qualityOf = (position: number) => draft.value.qualities[position];

const setQuality = (position: number, value: unknown) => {
  const grade = value === "" || value == null ? undefined : Number(value);

  draft.value = {
    ...draft.value,
    qualities: { ...draft.value.qualities, [position]: grade },
  };
};

const gradeValid = (grade?: number) =>
  grade !== undefined && Number.isInteger(grade) && grade >= 0 && grade <= 1000;

const valid = computed(
  () =>
    !!recipe.value &&
    gradedSlots.value.every((slot) => {
      const grade = qualityOf(slot.position);

      return props.optional && grade === undefined ? true : gradeValid(grade);
    }),
);

watch(valid, (value) => emit("valid", value), { immediate: true });

// The stats follow the grades as they are typed; a slot still blank reads as
// the neutral grade rather than as the worst one.
const previewQualityFor = (position: number) =>
  qualityOf(position) ?? NEUTRAL_QUALITY;
</script>

<template>
  <div class="crafting-step">
    <p class="crafting-step__hint">
      {{
        t(
          optional
            ? "labels.logistics.crafted.requestHint"
            : "labels.logistics.crafted.hint",
          { name: item.name },
        )
      }}
    </p>

    <BaseSelect
      v-if="recipeOptions.length > 1"
      v-model="recipeId"
      name="craftedBlueprint"
      :options="recipeOptions"
      :label="t('labels.logistics.crafted.blueprint')"
      :searchable="false"
    />

    <div class="crafting-step__slots">
      <FormInput
        v-for="slot in gradedSlots"
        :key="`${recipeId}-${slot.position}`"
        :model-value="qualityOf(slot.position)"
        :name="`craftedQuality${slot.position}`"
        :type="InputTypesEnum.NUMBER"
        :label="slotLabel(slot)"
        :min="0"
        :step="1"
        :max="1000"
        no-placeholder
        standalone
        @update:model-value="setQuality(slot.position, $event)"
      />
    </div>

    <BlueprintPreview
      v-if="recipe"
      :blueprint="recipe"
      :quality-for="previewQualityFor"
    />
  </div>
</template>

<style lang="scss" scoped>
.crafting-step__hint {
  margin: 0 0 16px;
  color: var(--color-text-dim, #959595);
}

.crafting-step__slots {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 0 12px;
}
</style>

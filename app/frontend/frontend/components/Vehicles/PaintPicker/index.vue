<script lang="ts">
export default {
  name: "VehiclePaintPicker",
};
</script>

<script lang="ts" setup>
import AddonOption from "@/frontend/components/Models/AddonOption/index.vue";
import type { AddonBadge } from "@/frontend/components/Models/AddonOption/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type ModelPaint, useModelPaints } from "@/services/fyApi";

type Props = {
  modelSlug: string;
  // In place of the model's catalogue paints, where the caller has a list that
  // also keeps the ship's own paints the catalogue has since hidden.
  paints?: ModelPaint[];
  // The paints the ship owns.
  modelValue?: string[];
  // Paints a synced pledge of the owner's resolves to, marked as a suggestion:
  // a pledge names no ship, so it cannot say which hull owns one.
  pledgedIds?: string[];
  // Where a heading already names the choice, the legend stays for screen
  // readers only.
  hideLegend?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  paints: undefined,
  modelValue: () => [],
  pledgedIds: () => [],
  hideLegend: false,
});

const emit = defineEmits<{ "update:modelValue": [value: string[]] }>();

const { t } = useI18n();

const { data: modelPaints, isLoading } = useModelPaints(() => props.modelSlug, {
  query: { enabled: () => !props.paints },
});

const paints = computed(() => props.paints || modelPaints.value);

const image = (paint: ModelPaint) =>
  paint.media.storeImage?.smallUrl || paint.media.storeImage?.url;

// A handful fits at a glance; a ship with a dozen liveries needs narrowing.
const SEARCH_THRESHOLD = 9;

const searchable = computed(
  () => (paints.value?.length || 0) > SEARCH_THRESHOLD,
);

const search = ref<string | number | null>("");

const visiblePaints = computed(() => {
  const term = String(search.value ?? "")
    .trim()
    .toLowerCase();
  const all = paints.value || [];
  if (!term) return all;

  return all.filter((paint) => paint.name.toLowerCase().includes(term));
});

const owned = (paint: ModelPaint) => props.modelValue.includes(paint.id);

const pledged = (paint: ModelPaint) => props.pledgedIds.includes(paint.id);

const badges = (paint: ModelPaint): AddonBadge[] => {
  const list: AddonBadge[] = [];

  if (pledged(paint)) {
    list.push({
      key: "pledged",
      label: t("labels.vehicle.ownedPaintsSelect.pledged"),
      variant: PillVariantsEnum.NEUTRAL,
    });
  }

  return list;
};

const toggle = (paint: ModelPaint) =>
  emit(
    "update:modelValue",
    owned(paint)
      ? props.modelValue.filter((id) => id !== paint.id)
      : [...props.modelValue, paint.id],
  );
</script>

<template>
  <fieldset class="paint-picker" :aria-busy="isLoading">
    <legend class="paint-picker__legend" :class="{ 'sr-only': hideLegend }">
      {{ t("labels.vehicle.ownedPaintsSelect.label") }}
    </legend>
    <!-- Standalone, so inside the vehicle form the search is not submitted
         with the vehicle. -->
    <FormInput
      v-if="searchable"
      v-model="search"
      name="paint-picker-search"
      class="paint-picker__search"
      :label="t('labels.vehicleOverview.searchPaints')"
      :placeholder="t('labels.vehicleOverview.searchPaints')"
      icon="fa-light fa-magnifying-glass"
      data-test="paint-picker-search"
      standalone
      no-label
      clearable
    />
    <div class="paint-picker__grid">
      <AddonOption
        v-for="paint in visiblePaints"
        :key="paint.id"
        :name="paint.name"
        :image="image(paint)"
        :badges="badges(paint)"
        :selected="owned(paint)"
        stacked
        test-id="paint-picker-choice"
        @toggle="toggle(paint)"
      />

      <p
        v-if="!isLoading && !visiblePaints.length"
        class="addon-options__empty"
        data-test="paint-picker-empty"
      >
        {{ t("labels.vehicle.ownedPaintsSelect.empty") }}
      </p>
    </div>
  </fieldset>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Vehicles/EditModal/Addons/index";

.paint-picker {
  min-width: 0;
  margin: 0 0 15px;
  padding: 0;
  border: 0;

  &__legend {
    margin-bottom: 6px;
    font-size: inherit;
  }

  &__search {
    margin-bottom: 10px;
  }

  // Two cards across the edit modal, one on a phone.
  &__grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
    gap: 10px;

    .addon-options__empty {
      grid-column: 1 / -1;
    }
  }
}
</style>

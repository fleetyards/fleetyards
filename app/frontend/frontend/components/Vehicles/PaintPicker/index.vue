<script lang="ts">
export default {
  name: "VehiclePaintPicker",
};
</script>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type ModelPaint, useModelPaints } from "@/services/fyApi";

type Props = {
  modelSlug: string;
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
  modelValue: () => [],
  pledgedIds: () => [],
  hideLegend: false,
});

const emit = defineEmits<{ "update:modelValue": [value: string[]] }>();

const { t } = useI18n();

const { data: paints, isLoading } = useModelPaints(() => props.modelSlug);

const thumb = (paint: ModelPaint) =>
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
      <button
        v-for="paint in visiblePaints"
        :key="paint.id"
        type="button"
        class="paint-picker__choice"
        :class="{ 'paint-picker__choice--selected': owned(paint) }"
        :aria-pressed="owned(paint)"
        data-test="paint-picker-choice"
        @click="toggle(paint)"
      >
        <img
          v-if="thumb(paint)"
          :src="thumb(paint)"
          alt=""
          class="paint-picker__image"
        />
        <span v-else class="paint-picker__image" />
        <span class="paint-picker__name">{{ paint.name }}</span>
        <span
          v-if="pledged(paint)"
          class="paint-picker__pledged"
          data-test="paint-picker-pledged"
        >
          {{ t("labels.vehicle.ownedPaintsSelect.pledged") }}
        </span>
      </button>
    </div>
  </fieldset>
</template>

<style lang="scss" scoped>
.paint-picker {
  margin: 0 0 15px;
  padding: 0;
  border: 0;

  &__legend {
    margin-bottom: 6px;
    font-size: inherit;
  }

  &__search {
    margin-bottom: 8px;
  }

  &__grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
    gap: 8px;
    max-height: 320px;
    overflow-y: auto;
  }

  &__choice {
    padding: 0;
    overflow: hidden;
    border: 2px solid var(--color-edge-soft);
    border-radius: 6px;
    background: var(--color-gray-black);
    color: inherit;
    text-align: left;
    cursor: pointer;

    &:hover,
    &:focus-visible {
      border-color: var(--color-edge-strong);
    }

    &--selected,
    &--selected:hover {
      border-color: var(--color-gold);
    }
  }

  &__image {
    display: block;
    width: 100%;
    height: 64px;
    object-fit: cover;
  }

  &__pledged {
    display: block;
    padding: 0 8px 6px;
    color: var(--color-text-dim);
    font-size: 0.7rem;
  }

  &__name {
    display: block;
    padding: 6px 8px;
    overflow: hidden;
    font-size: 0.75rem;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
}
</style>

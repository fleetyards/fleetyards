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
  modelValue?: string | null;
  // The model's own render, for the "no paint" choice.
  defaultImage?: string;
  // Where a heading already names the choice, the legend stays for screen
  // readers only.
  hideLegend?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  defaultImage: undefined,
  hideLegend: false,
});

const emit = defineEmits<{ "update:modelValue": [value: string | null] }>();

const { t } = useI18n();

const { data: paints, isLoading } = useModelPaints(() => props.modelSlug);

const thumb = (paint: ModelPaint) =>
  paint.media.storeImage?.smallUrl || paint.media.storeImage?.url;

type Choice = {
  id: string | null;
  name: string;
  image?: string;
};

const choices = computed<Choice[]>(() => [
  {
    id: null,
    name: t("labels.vehicleOverview.noPaint"),
    image: props.defaultImage,
  },
  ...(paints.value || []).map((paint) => ({
    id: paint.id,
    name: paint.name,
    image: thumb(paint),
  })),
]);

// A handful fits at a glance; a ship with a dozen liveries needs narrowing.
const SEARCH_THRESHOLD = 9;

const searchable = computed(
  () => (paints.value?.length || 0) > SEARCH_THRESHOLD,
);

const search = ref<string | number | null>("");

const visibleChoices = computed(() => {
  const term = String(search.value ?? "")
    .trim()
    .toLowerCase();
  if (!term) return choices.value;

  return choices.value.filter((choice) =>
    choice.name.toLowerCase().includes(term),
  );
});

const selected = (choice: Choice) => (props.modelValue ?? null) === choice.id;
</script>

<template>
  <fieldset class="paint-picker" :aria-busy="isLoading">
    <legend class="paint-picker__legend" :class="{ 'sr-only': hideLegend }">
      {{ t("labels.vehicle.modelPaintSelect.label") }}
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
        v-for="choice in visibleChoices"
        :key="choice.id ?? 'none'"
        type="button"
        class="paint-picker__choice"
        :class="{ 'paint-picker__choice--selected': selected(choice) }"
        :aria-pressed="selected(choice)"
        data-test="paint-picker-choice"
        @click="emit('update:modelValue', choice.id)"
      >
        <img
          v-if="choice.image"
          :src="choice.image"
          alt=""
          class="paint-picker__image"
        />
        <span v-else class="paint-picker__image" />
        <span class="paint-picker__name">{{ choice.name }}</span>
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

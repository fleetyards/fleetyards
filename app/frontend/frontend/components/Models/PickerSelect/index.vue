<script lang="ts">
export default {
  name: "ModelPickerSelect",
};
</script>

<script lang="ts" setup>
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { type ModelQuery, useModel } from "@/services/fyApi";

type Props = {
  name: string;
  modelValue?: string;
  label: string;
  // Narrows the picker, e.g. to flight-ready ships.
  query?: ModelQuery;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  query: undefined,
});

const emit = defineEmits<{
  "update:modelValue": [slug?: string];
}>();

const { t } = useI18n();

const comlink = useComlink();

const pickerId = useId();

// Looked up for its name and image: the value is only the slug, the way the
// URL carries it.
const { data: model } = useModel(
  computed(() => props.modelValue || ""),
  {
    query: { enabled: computed(() => !!props.modelValue) },
  },
);

// Off the value first: the query keeps its last answer after a clear, and a
// cleared select must not go on naming that ship.
const chosen = computed(() => (props.modelValue ? model.value : undefined));

const image = computed(() => chosen.value?.media.storeImage?.smallUrl);

const prompt = computed(() => {
  if (!props.modelValue) return props.label;

  return chosen.value?.name ?? props.modelValue;
});

// The standard ship picker, one ship at a time: search, filters and the
// hangar toggle come with it, which a dropdown of a few hundred ships lacks.
const open = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Models/PickerSelect/Modal.vue"),
    props: { pickerId, title: props.label, query: props.query },
    wide: true,
  });
};

const clear = () => {
  emit("update:modelValue", undefined);
};

const offPicked = ref<() => void>();

onMounted(() => {
  offPicked.value = comlink.on("model-picker-select-picked", (picked) => {
    if (picked.pickerId === pickerId) emit("update:modelValue", picked.slug);
  });
});

onUnmounted(() => {
  offPicked.value?.();
});
</script>

<template>
  <div
    class="base-select model-picker-select"
    :data-test="`model-picker-select-${name}`"
  >
    <div v-if="modelValue" class="field-label">
      <label :for="`${name}-${pickerId}`">{{ label }}</label>
    </div>
    <div class="model-picker-select__row">
      <button
        :id="`${name}-${pickerId}`"
        type="button"
        class="base-select-title"
        :class="{ selected: !!modelValue, hasLabel: !!modelValue }"
        aria-haspopup="dialog"
        :aria-label="label"
        data-test="model-picker-select-trigger"
        @click="open"
      >
        <span class="model-picker-select__value">
          <img
            v-if="image"
            :src="image"
            alt=""
            class="model-picker-select__image"
          />
          <span class="base-select-title-prompt">
            {{ prompt }}
          </span>
        </span>
        <i class="fa fa-chevron-down" />
      </button>
      <button
        v-if="modelValue"
        type="button"
        class="model-picker-select__clear"
        :aria-label="t('actions.clear')"
        data-test="model-picker-select-clear"
        @click="clear"
      >
        <i class="fa-light fa-times" />
      </button>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/shared/components/base/Select/index";

.model-picker-select__row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.model-picker-select__value {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}

.model-picker-select__image {
  width: 36px;
  height: 22px;
  flex-shrink: 0;
  border-radius: 3px;
  object-fit: cover;
}

.model-picker-select__clear {
  flex-shrink: 0;
  width: 32px;
  height: var(--field-h, 43px);
  border: 0;
  background: none;
  color: var(--color-text-dim, #959595);
  cursor: pointer;

  &:hover {
    color: var(--color-text, #c8c8c8);
  }
}
</style>

<script lang="ts">
export default {
  name: "FeaturePercentageGate",
};
</script>

<script lang="ts" setup>
import Slider from "@/shared/components/base/Slider/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  name: string;
  label: string;
  value: number;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
});

const emit = defineEmits<{
  apply: [value: number];
}>();

const { t } = useI18n();

// Slider and input only move a draft. A slider that saved on release sent a
// change for every accidental drag; nothing reaches the flag before Apply.
const draft = ref(props.value);

watch(
  () => props.value,
  (value) => {
    draft.value = value;
  },
);

const clamp = (value: number) =>
  Math.min(100, Math.max(0, Math.round(Number.isFinite(value) ? value : 0)));

const inputValue = computed({
  get: () => draft.value,
  set: (value: string | number | null | undefined) => {
    draft.value = clamp(Number(value));
  },
});

const changed = computed(() => draft.value !== props.value);

const apply = () => {
  if (!changed.value) return;

  emit("apply", draft.value);
};
</script>

<template>
  <div class="feature-percentage-gate" :data-test="`percentage-gate-${name}`">
    <Slider
      v-model="draft"
      class="feature-percentage-gate__slider"
      :min="0"
      :max="100"
      process
      :label="label"
    />
    <div class="feature-percentage-gate__entry">
      <FormInput
        v-model="inputValue"
        :name="`feature-${name}`"
        type="number"
        :min="0"
        :max="100"
        :label="label"
        no-label
        inline
        standalone
        class="feature-percentage-gate__input"
        :data-test="`percentage-input-${name}`"
      />
      <span class="feature-percentage-gate__unit" aria-hidden="true">%</span>
      <Btn
        :disabled="!changed"
        :loading="loading"
        :data-test="`percentage-apply-${name}`"
        @click="apply"
      >
        {{ t("actions.apply") }}
      </Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.feature-percentage-gate {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem 1rem;
}

.feature-percentage-gate__slider {
  flex: 1 1 240px;
  min-width: 200px;
}

.feature-percentage-gate__entry {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.feature-percentage-gate__input {
  width: 5.5rem;
}

.feature-percentage-gate__unit {
  color: var(--color-text-dim);
}
</style>

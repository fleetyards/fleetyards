<script lang="ts">
export default {
  name: "PayoutsPayoutWeightControl",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  PRESET_WEIGHTS,
  FULL_WEIGHT,
} from "@/frontend/components/Payouts/PayoutWeightControl/types";

interface Props {
  weight?: string;
  disabled?: boolean;
  loading?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  weight: "1.0",
  disabled: false,
  loading: false,
});

const emit = defineEmits<{ update: [weight: string] }>();

const { t } = useI18n();

// The column is a decimal carried as a string, so every comparison is made on
// the number rather than the text -- "0.5" and "0.50" are the same share and
// the API may answer with either.
const current = computed(() => Number(props.weight));

const isPreset = computed(() =>
  PRESET_WEIGHTS.some((preset) => preset.value === current.value),
);

// A weight no preset can express keeps the field open on its own, so a ledger
// that already carries one does not hide it behind a button.
const customOpen = ref(!isPreset.value);

const customValue = ref(String(current.value));

watch(
  () => props.weight,
  () => {
    customValue.value = String(current.value);

    if (!isPreset.value) {
      customOpen.value = true;
    }
  },
);

// What we have asked the parent for and not yet heard back about. Two events
// can land before `props.weight` catches up, and without this the second would
// compare against the stale weight and send the same PATCH again.
//
// It has to be released when the request *finishes*, not when the weight
// changes: a refused PATCH leaves the parent on the old weight, so waiting for
// that would swallow the retry and leave the only way back a detour through a
// different weight.
const inFlight = ref<string | null>(null);

const emitWeight = (weight: string) => {
  if (inFlight.value === weight) {
    return;
  }

  inFlight.value = weight;
  emit("update", weight);
};

watch(
  () => props.loading,
  (loading, wasLoading) => {
    if (wasLoading && !loading) {
      inFlight.value = null;
    }
  },
);

// A parent that tracks no loading state still releases the guard by answering
// with a new weight.
watch(
  () => props.weight,
  () => {
    inFlight.value = null;
  },
);

const onPick = (value: number) => {
  if (props.disabled || value === current.value) {
    return;
  }

  emitWeight(String(value));
};

const onCustom = () => {
  if (props.disabled) {
    return;
  }

  const value = Number(String(customValue.value).replace(",", "."));

  // The API refuses these too. Declined here so a mistyped share does not cost
  // a round trip and an error toast.
  if (!Number.isFinite(value) || value <= 0) {
    customValue.value = String(current.value);
    return;
  }

  if (value === current.value) {
    return;
  }

  emitWeight(value.toFixed(2));
};
</script>

<template>
  <div class="payout-weight">
    <Btn
      v-for="preset in PRESET_WEIGHTS"
      :key="preset.value"
      :size="BtnSizesEnum.XS"
      :variant="BtnVariantsEnum.GHOST"
      :active="preset.value === current"
      :disabled="disabled"
      :loading="loading && preset.value === current"
      class="payout-weight__preset"
      :class="{
        'payout-weight__preset--adjusted':
          preset.value === current && preset.value !== FULL_WEIGHT,
      }"
      :data-test="`payout-weight-${preset.value}`"
      @click="onPick(preset.value)"
    >
      {{ preset.label }}
    </Btn>

    <Btn
      :size="BtnSizesEnum.XS"
      :variant="BtnVariantsEnum.GHOST"
      :active="!isPreset"
      :disabled="disabled"
      :aria-label="t('labels.payouts.customWeight')"
      class="payout-weight__preset"
      :class="{ 'payout-weight__preset--adjusted': !isPreset }"
      data-test="payout-weight-custom"
      @click="customOpen = !customOpen"
    >
      …
    </Btn>

    <!-- A native input rather than FormInput: the smallest field the form
         components offer is 43px, which towers over the 29px chip row it sits
         in. Styled from the same field tokens FormInput uses. -->
    <input
      v-if="customOpen"
      v-model="customValue"
      class="payout-weight__field"
      type="number"
      min="0.01"
      max="999.99"
      step="0.05"
      :disabled="disabled"
      :aria-label="t('labels.payouts.weight')"
      data-test="payout-weight-field"
      @change="onCustom"
      @keyup.enter="onCustom"
    />
  </div>
</template>

<style lang="scss" scoped>
.payout-weight {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
}

/* Only a weight that is not a full share is worth a colour -- above as well as
   below, since both are a deviation the reader has to be able to see. A full
   share is the resting state on almost every row, and lighting all of them
   turns the column into noise rather than a signal, which is the same call the
   metric heading makes about its status dot. */
.payout-weight__preset--adjusted {
  box-shadow: inset 0 -2px 0 -1px var(--color-gold, #d4af37);
}

.payout-weight__field {
  width: 74px;
  height: 29px;
  padding: 0 8px;
  font-family: inherit;
  font-size: 15px;
  line-height: 1;
  color: var(--color-lifted, #eee);
  background: var(--color-field, rgb(18 20 23 / 0.96));
  border: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
  border-radius: var(--radius-control-bare, 6px);

  &:focus-visible {
    outline: 1px solid var(--color-primary, #428bca);
    outline-offset: 1px;
  }

  &:disabled {
    opacity: 0.5;
  }
}
</style>

<script lang="ts">
export default {
  name: "SupportProgress",
};
</script>

<script lang="ts" setup>
import { useSupportersProgress } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useCurrencyFormat } from "@/shared/composables/useCurrencyFormat";
import ProgressBar from "@/shared/components/ProgressBar/index.vue";

type Props = {
  compact?: boolean;
};

withDefaults(defineProps<Props>(), {
  compact: false,
});

const { t } = useI18n();
const { formatCents } = useCurrencyFormat();

const { data: progress } = useSupportersProgress();

const goalAmount = computed(() => progress.value?.goal?.amountCents ?? 0);
const totalAmount = computed(
  () => progress.value?.monthlyTotal.amountCents ?? 0,
);
const currency = computed(
  () =>
    progress.value?.goal?.currency ??
    progress.value?.monthlyTotal.currency ??
    "EUR",
);

const percent = computed(() => {
  if (!goalAmount.value) return 0;
  return Math.min(
    100,
    Math.round((totalAmount.value / goalAmount.value) * 100),
  );
});

const formattedTotal = computed(() =>
  formatCents(totalAmount.value, currency.value),
);

const formattedGoal = computed(() =>
  formatCents(goalAmount.value, currency.value),
);
</script>

<template>
  <div
    class="support-progress"
    :class="{ 'support-progress--compact': compact }"
  >
    <div class="support-progress__header">
      <span class="support-progress__total">{{ formattedTotal }}</span>
      <span v-if="progress?.goal" class="support-progress__goal">
        / {{ formattedGoal }}
      </span>
    </div>
    <ProgressBar :progress="percent" />
    <p v-if="!compact && progress?.goal" class="support-progress__caption">
      {{ t("texts.support.thisMonth") }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>

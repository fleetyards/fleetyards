<script lang="ts">
export default {
  name: "PayoutsPayoutSummary",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import type { PayoutLedger } from "@/services/fyApi";

type Props = {
  ledger: PayoutLedger;
};

const props = defineProps<Props>();

const { t, toUEC } = useI18n();

const profit = computed(() => Number(props.ledger.profit ?? 0));

// Deliberately no per-head tile here. profit / count in JS floats disagrees
// with the server's largest-remainder share by a hundredth, and the balances
// table below already gives every participant their exact share.

// What the profit is actually divided by, which stops being the head count the
// moment somebody is on less than a full share. Shown only when the two differ:
// on an unweighted ledger it would repeat the number above it. The figure is
// the server's -- summing the weights here would be the float arithmetic the
// comment above refuses.
const totalWeight = computed(() => Number(props.ledger.totalWeight ?? 0));

const weighted = computed(
  () => totalWeight.value !== Number(props.ledger.participantsCount ?? 0),
);
</script>

<template>
  <div class="payout-summary">
    <div class="payout-summary__item">
      <span class="payout-summary__label">
        {{ t("labels.payouts.totalIncome") }}
      </span>
      <span
        class="payout-summary__value payout-summary__value--income"
        v-html="toUEC(Number(ledger.totalIncome ?? 0))"
      />
    </div>
    <div class="payout-summary__item">
      <span class="payout-summary__label">
        {{ t("labels.payouts.totalExpenses") }}
      </span>
      <span
        class="payout-summary__value payout-summary__value--expense"
        v-html="toUEC(Number(ledger.totalExpenses ?? 0))"
      />
    </div>
    <div class="payout-summary__item">
      <span class="payout-summary__label">
        {{ t("labels.payouts.profit") }}
      </span>
      <span
        class="payout-summary__value"
        :class="{
          'payout-summary__value--income': profit > 0,
          'payout-summary__value--expense': profit < 0,
        }"
        v-html="toUEC(profit)"
      />
    </div>
    <div class="payout-summary__item">
      <span class="payout-summary__label">
        {{ t("labels.payouts.participants") }}
      </span>
      <span class="payout-summary__value">
        {{ ledger.participantsCount ?? 0 }}
      </span>
      <span
        v-if="weighted"
        class="payout-summary__shares"
        data-test="payout-summary-shares"
      >
        {{ ledger.totalWeight }} {{ t("labels.payouts.shares") }}
      </span>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.payout-summary {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
  padding: 14px 16px;
  background: var(--color-surface, rgb(39 43 48 / 0.9));
  border: 1px solid var(--color-edge-faint, rgba(255, 255, 255, 0.08));
  border-radius: var(--radius-control-bare, 6px);

  @media (min-width: 768px) {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }
}

.payout-summary__item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.payout-summary__label {
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--color-muted, #7a8288);
}

.payout-summary__value {
  font-size: 20px;
}

.payout-summary__value--income {
  color: var(--color-success, #4caf50);
}

.payout-summary__value--expense {
  color: var(--color-danger, #f44336);
}

.payout-summary__shares {
  font-size: 11px;
  color: var(--color-gold, #d4af37);
}
</style>

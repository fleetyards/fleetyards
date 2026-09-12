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

// What one participant is entitled to once costs are reimbursed. Shown up
// front because it is the number everyone actually wants from the page.
const perHead = computed(() => {
  const count = props.ledger.participantsCount ?? 0;

  return count ? profit.value / count : 0;
});
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
        {{ t("labels.payouts.share") }}
      </span>
      <span class="payout-summary__value" v-html="toUEC(perHead)" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.payout-summary {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
  padding: 14px 16px;
  background: var(--color-lifted, rgba(255, 255, 255, 0.03));
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
  color: var(--color-muted, #999);
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
</style>

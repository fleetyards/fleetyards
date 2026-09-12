<script lang="ts">
export default {
  name: "PayoutsPayoutBalances",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import type { PayoutBalance } from "@/services/fyApi";

type Props = {
  balances: PayoutBalance[];
};

const props = defineProps<Props>();

const { t, toUEC } = useI18n();

// A positive net means they are holding more than their share and owe the
// difference; negative means they are owed. Zero is settled up.
const rows = computed(() =>
  props.balances.map((balance) => {
    const net = Number(balance.net ?? 0);

    return {
      balance,
      net,
      owes: net > 0,
      owed: net < 0,
    };
  }),
);
</script>

<template>
  <div class="payout-balances">
    <div class="payout-balances__row payout-balances__row--head">
      <span>{{ t("labels.payouts.participant") }}</span>
      <span>{{ t("labels.payouts.paid") }}</span>
      <span>{{ t("labels.payouts.held") }}</span>
      <span>{{ t("labels.payouts.share") }}</span>
      <span>{{ t("labels.payouts.net") }}</span>
    </div>
    <div
      v-for="row in rows"
      :key="row.balance.participant.id"
      class="payout-balances__row"
      :data-test="`payout-balance-${row.balance.participant.id}`"
    >
      <span class="payout-balances__name">
        {{ row.balance.participant.displayName }}
        <span v-if="row.balance.participant.guest" class="payout-balances__tag">
          {{ t("labels.payouts.guest") }}
        </span>
      </span>
      <span v-html="toUEC(Number(row.balance.paid ?? 0))" />
      <span v-html="toUEC(Number(row.balance.held ?? 0))" />
      <span v-html="toUEC(Number(row.balance.share ?? 0))" />
      <span
        class="payout-balances__net"
        :class="{
          'payout-balances__net--owes': row.owes,
          'payout-balances__net--owed': row.owed,
        }"
        v-html="toUEC(Math.abs(row.net))"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.payout-balances {
  display: flex;
  flex-direction: column;
  overflow-x: auto;
}

.payout-balances__row {
  display: grid;
  grid-template-columns: minmax(140px, 2fr) repeat(4, minmax(90px, 1fr));
  gap: 12px;
  padding: 10px 0;
  border-bottom: 1px solid var(--color-edge-faint, rgba(255, 255, 255, 0.08));

  > span:not(:first-child) {
    text-align: right;
  }
}

.payout-balances__row--head {
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--color-muted, #999);
}

.payout-balances__name {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.payout-balances__tag {
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  padding: 1px 6px;
  border-radius: var(--radius-control-bare, 6px);
  border: 1px solid var(--color-edge-soft, rgba(255, 255, 255, 0.15));
  color: var(--color-muted, #999);
}

.payout-balances__net--owes {
  color: var(--color-danger, #f44336);
}

.payout-balances__net--owed {
  color: var(--color-success, #4caf50);
}
</style>

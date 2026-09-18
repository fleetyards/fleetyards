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
  // The balances are their own request. The header row alone, with nothing
  // under it, reads as a ledger where nobody is owed anything.
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), { loading: false });

const skeletonVisible = computed(() => props.loading && !props.balances.length);

// Enough to hold the panel open without claiming a head count: three is the
// smallest number that still reads as a list rather than as one stray row.
const SKELETON_ROWS = 3;

const { t, toUEC } = useI18n();

// A positive net means they are holding more than their share and owe the
// difference; negative means they are owed. Zero is settled up.
const rows = computed(() =>
  props.balances.map((balance) => {
    const net = Number(balance.net ?? 0);
    const weight = Number(balance.participant.weight ?? 1);

    return {
      balance,
      net,
      owes: net > 0,
      owed: net < 0,
      weight,
      // Above a full share as well as below: both are a deviation the reader
      // has to be able to see, and calling 1.5 a reduced share was wrong.
      adjusted: weight !== 1,
    };
  }),
);

// Worth a column of its own only once somebody is not on a full share. On a
// ledger where everybody is, it would be a column of identical ones.
const showWeight = computed(() => rows.value.some((row) => row.adjusted));
</script>

<template>
  <div
    class="payout-balances"
    :class="{ 'payout-balances--weighted': showWeight }"
  >
    <div class="payout-balances__row payout-balances__row--head">
      <span>{{ t("labels.payouts.participant") }}</span>
      <span v-if="showWeight">{{ t("labels.payouts.weight") }}</span>
      <span>{{ t("labels.payouts.paid") }}</span>
      <span>{{ t("labels.payouts.held") }}</span>
      <span>{{ t("labels.payouts.share") }}</span>
      <span>{{ t("labels.payouts.net") }}</span>
    </div>
    <!-- Placeholders inside the same grid row rather than a list beside it, so
         every bar stands in the column its figure will land in. -->
    <div
      v-for="row in skeletonVisible ? SKELETON_ROWS : 0"
      :key="`payout-balances__skeleton-${row}`"
      class="payout-balances__row"
      aria-hidden="true"
      data-test="payout-balances-skeleton-row"
    >
      <span class="payout-balances__name">
        <span class="skeleton-bar skeleton-bar--name" />
      </span>
      <span v-if="showWeight"><span class="skeleton-bar" /></span>
      <span><span class="skeleton-bar" /></span>
      <span><span class="skeleton-bar" /></span>
      <span><span class="skeleton-bar" /></span>
      <span><span class="skeleton-bar" /></span>
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
      <span
        v-if="showWeight"
        class="payout-balances__weight"
        :class="{ 'payout-balances__weight--adjusted': row.adjusted }"
        :data-label="t('labels.payouts.weight')"
      >
        {{ row.balance.participant.weight }}
      </span>
      <span
        :data-label="t('labels.payouts.paid')"
        v-html="toUEC(Number(row.balance.paid ?? 0))"
      />
      <span
        :data-label="t('labels.payouts.held')"
        v-html="toUEC(Number(row.balance.held ?? 0))"
      />
      <span
        :data-label="t('labels.payouts.share')"
        v-html="toUEC(Number(row.balance.share ?? 0))"
      />
      <!-- The sign carries owe-vs-owed on its own; the colour only
           reinforces it, so the column still reads in print or to someone who
           cannot separate the two hues. -->
      <span
        class="payout-balances__net"
        :class="{
          'payout-balances__net--owes': row.owes,
          'payout-balances__net--owed': row.owed,
        }"
        :data-label="t('labels.payouts.net')"
      >
        <!-- toUEC renders 0 as "-", which reads as a figure nobody worked out
             rather than as the one good outcome. -->
        <template v-if="!row.owes && !row.owed">
          {{ t("labels.payouts.even") }}
        </template>
        <template v-else>
          <template v-if="row.owes">−</template>
          <template v-else>+</template>
          <span v-html="toUEC(Math.abs(row.net))" />
        </template>
      </span>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/shared/components/skeleton";

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

.payout-balances--weighted .payout-balances__row {
  grid-template-columns: minmax(140px, 2fr) minmax(64px, 0.6fr) repeat(
      4,
      minmax(90px, 1fr)
    );
}

.payout-balances__row--head {
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--color-muted, #7a8288);
}

.payout-balances__name {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

// The figure columns are right-aligned, so their bars have to be too - a bar
// filling the cell would read as a very long number.
.payout-balances__row[aria-hidden="true"] .skeleton-bar {
  width: 60%;

  &--name {
    width: 55%;
    max-width: 180px;
  }
}

.payout-balances__tag {
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  padding: 1px 6px;
  border-radius: var(--radius-control-bare, 6px);
  border: 1px solid var(--color-edge-soft, rgba(255, 255, 255, 0.15));
  color: var(--color-muted, #7a8288);
}

.payout-balances__weight--adjusted {
  color: var(--color-gold, #d4af37);
}

.payout-balances__net--owes {
  color: var(--color-danger, #f44336);
}

.payout-balances__net--owed {
  color: var(--color-success, #4caf50);
}

/*
 * Six columns is past what a phone can carry. The table scrolled sideways at
 * five already, which put the balance -- the column people actually came for --
 * off the edge; below the md breakpoint each row becomes a block instead, and
 * every figure carries the heading it lost with the header row.
 */
@media (max-width: 991px) {
  .payout-balances__row--head {
    display: none;
  }

  .payout-balances__row,
  .payout-balances--weighted .payout-balances__row {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 8px;
    padding: 12px 0;

    > span:not(:first-child) {
      text-align: left;
    }
  }

  .payout-balances__name {
    grid-column: 1 / -1;
  }

  .payout-balances__row > span[data-label]::before {
    content: attr(data-label);
    display: block;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    color: var(--color-muted, #7a8288);
  }
}
</style>

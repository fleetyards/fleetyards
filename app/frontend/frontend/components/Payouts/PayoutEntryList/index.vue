<script lang="ts">
export default {
  name: "PayoutsPayoutEntryList",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import type { PayoutEntry, PayoutParticipant } from "@/services/fyApi";

type Props = {
  payoutLedgerId: string;
  entries: PayoutEntry[];
  participants: PayoutParticipant[];
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), { editable: false });

const { t, toUEC, l } = useI18n();
const comlink = useComlink();

const onEdit = (entry: PayoutEntry) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Payouts/PayoutEntryModal/index.vue"),
    props: {
      payoutLedgerId: props.payoutLedgerId,
      participants: props.participants,
      entry,
    },
  });
};
</script>

<template>
  <div class="payout-entries">
    <p v-if="!entries.length" class="payout-entries__empty">
      {{ t("empty.payouts.entries") }}
    </p>

    <div
      v-for="entry in entries"
      :key="entry.id"
      class="payout-entries__row"
      data-test="payout-entry"
    >
      <i
        class="payout-entries__icon fa-light"
        :class="entry.entryType === 'income' ? 'fa-arrow-down' : 'fa-arrow-up'"
        :title="t(`labels.payouts.${entry.entryType}`)"
      />

      <div class="payout-entries__detail">
        <span class="payout-entries__description">{{ entry.description }}</span>
        <span class="payout-entries__meta">
          {{ entry.participant?.displayName }}
          <template v-if="entry.occurredAt">
            · {{ l(entry.occurredAt) }}
          </template>
        </span>
      </div>

      <span
        class="payout-entries__amount"
        :class="`payout-entries__amount--${entry.entryType}`"
        v-html="toUEC(Number(entry.amount ?? 0))"
      />

      <Btn
        v-if="editable"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.BARE"
        :aria-label="t('headlines.payouts.editEntry')"
        @click="onEdit(entry)"
      >
        <i class="fa-light fa-pen" />
      </Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.payout-entries {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.payout-entries__empty {
  margin: 0;
  color: var(--color-muted, #999);
}

.payout-entries__row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 12px;
  border-bottom: 1px solid var(--color-edge-faint, rgba(255, 255, 255, 0.08));
}

.payout-entries__icon {
  color: var(--color-muted, #999);
}

.payout-entries__detail {
  display: flex;
  flex-direction: column;
  flex: 1 1 auto;
  min-width: 0;
}

.payout-entries__description {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.payout-entries__meta {
  font-size: 11px;
  color: var(--color-muted, #999);
}

.payout-entries__amount--income {
  color: var(--color-success, #4caf50);
}

.payout-entries__amount--expense {
  color: var(--color-danger, #f44336);
}
</style>

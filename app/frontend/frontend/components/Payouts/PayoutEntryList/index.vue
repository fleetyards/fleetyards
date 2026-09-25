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
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  PayoutEntryReviewStatusEnum,
  useApprovePayoutEntry as useApprovePayoutEntryMutation,
  type PayoutEntry,
  type PayoutParticipant,
} from "@/services/fyApi";
import type { ApiError } from "@/shared/types/api-error";

type Props = {
  payoutLedgerId: string;
  entries: PayoutEntry[];
  participants: PayoutParticipant[];
  editable?: boolean;
  // Whether the viewer may approve or decline an expense somebody else is
  // waiting on -- the ledger's managers.
  reviewable?: boolean;
  expensesAllowed?: boolean;
  // The entries are a query of their own, answering after the ledger that
  // frames this panel - so without this the panel says "nothing recorded yet"
  // about a ledger that is still being read.
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
  reviewable: false,
  expensesAllowed: true,
  loading: false,
});

// The same rule the API applies: a row may only be corrected by someone who
// may record against the participant it names. `participants` is already
// narrowed to that set by the ledger, so offering a pen on every entry would
// only hand out 403s.
const editableParticipantIds = computed(
  () => new Set(props.participants.map((participant) => participant.id)),
);

const editableEntry = (entry: PayoutEntry) =>
  props.editable &&
  !!entry.payoutParticipantId &&
  editableParticipantIds.value.has(entry.payoutParticipantId);

const { t, toUEC, l } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();

const reviewing = (entry: PayoutEntry) =>
  props.reviewable &&
  entry.reviewStatus === PayoutEntryReviewStatusEnum.PENDING;

const approvingId = ref<string | null>(null);

const approveMutation = useApprovePayoutEntryMutation();

const onApprove = async (entry: PayoutEntry) => {
  approvingId.value = entry.id;

  await approveMutation
    .mutateAsync({ payoutLedgerId: props.payoutLedgerId, id: entry.id })
    .then(() => {
      displaySuccess({ text: t("messages.payouts.expenseApproved") });
      comlink.emit("payout-ledger-changed");
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      approvingId.value = null;
    });
};

const onDecline = (entry: PayoutEntry) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Payouts/PayoutEntryDeclineModal/index.vue"),
    props: { payoutLedgerId: props.payoutLedgerId, entry },
  });
};

const onEdit = (entry: PayoutEntry) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Payouts/PayoutEntryModal/index.vue"),
    props: {
      payoutLedgerId: props.payoutLedgerId,
      participants: props.participants,
      expensesAllowed: props.expensesAllowed,
      entry,
    },
  });
};
</script>

<template>
  <div class="payout-entries">
    <RowsSkeleton v-if="loading && !entries.length" icon trailing />

    <p v-else-if="!entries.length" class="payout-entries__empty">
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
        <!-- Only the two states that change what the entry means. An approved
             expense counts like any other, so it carries no mark. -->
        <span
          v-if="entry.reviewStatus !== PayoutEntryReviewStatusEnum.APPROVED"
          class="payout-entries__review"
          :class="`payout-entries__review--${entry.reviewStatus}`"
          data-test="payout-entry-review"
        >
          {{ t(`labels.payouts.review.${entry.reviewStatus}`) }}
          <template v-if="entry.declineReason">
            · {{ entry.declineReason }}
          </template>
        </span>
      </div>

      <span
        class="payout-entries__amount"
        :class="[
          `payout-entries__amount--${entry.entryType}`,
          {
            'payout-entries__amount--uncounted':
              entry.reviewStatus !== PayoutEntryReviewStatusEnum.APPROVED,
          },
        ]"
        v-html="toUEC(Number(entry.amount ?? 0))"
      />

      <template v-if="reviewing(entry)">
        <Btn
          :size="BtnSizesEnum.SM"
          :loading="approvingId === entry.id"
          data-test="payout-entry-approve"
          @click="onApprove(entry)"
        >
          {{ t("actions.payouts.approveExpense") }}
        </Btn>
        <Btn
          :size="BtnSizesEnum.SM"
          :variant="BtnVariantsEnum.BARE"
          data-test="payout-entry-decline"
          @click="onDecline(entry)"
        >
          {{ t("actions.payouts.declineExpense") }}
        </Btn>
      </template>

      <Btn
        v-if="editableEntry(entry)"
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
  color: var(--color-text-dim, #959595);
}

.payout-entries__row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 12px;
  border-bottom: 1px solid var(--color-edge-faint, rgba(255, 255, 255, 0.08));
}

.payout-entries__icon {
  color: var(--color-muted, #7a8288);
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
  color: var(--color-text-dim, #959595);
}

.payout-entries__review {
  font-size: 11px;
}

.payout-entries__review--pending {
  color: var(--color-warning, #ff9800);
}

.payout-entries__review--declined {
  color: var(--color-danger, #f44336);
}

.payout-entries__amount--uncounted {
  opacity: 0.5;
  text-decoration: line-through;
}

.payout-entries__amount--income {
  color: var(--color-success, #4caf50);
}

.payout-entries__amount--expense {
  color: var(--color-danger, #f44336);
}
</style>

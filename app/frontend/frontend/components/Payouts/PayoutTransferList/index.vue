<script lang="ts">
export default {
  name: "PayoutsPayoutTransferList",
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
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useConfirmPayoutTransfer as useConfirmPayoutTransferMutation,
  useUnconfirmPayoutTransfer as useUnconfirmPayoutTransferMutation,
  type PayoutTransfer,
} from "@/services/fyApi";
import type { ApiError } from "@/shared/types/api-error";

type Props = {
  payoutLedgerId: string;
  transfers: PayoutTransfer[];
  // Transfers computed from an open ledger are a preview: nobody has agreed to
  // pay them yet, so there is nothing to tick off.
  preview?: boolean;
};

const props = withDefaults(defineProps<Props>(), { preview: false });

const { t, toUEC } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();

const busyId = ref<string | null>(null);

const confirmMutation = useConfirmPayoutTransferMutation();
const unconfirmMutation = useUnconfirmPayoutTransferMutation();

const onToggle = async (transfer: PayoutTransfer) => {
  busyId.value = transfer.id;

  const mutation = transfer.confirmed ? unconfirmMutation : confirmMutation;

  await mutation
    .mutateAsync({ payoutLedgerId: props.payoutLedgerId, id: transfer.id })
    .then(() => {
      comlink.emit("payout-ledger-changed");
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      busyId.value = null;
    });
};
</script>

<template>
  <div class="payout-transfers">
    <p v-if="!transfers.length" class="payout-transfers__empty">
      {{ t("empty.payouts.transfers") }}
    </p>

    <div
      v-for="transfer in transfers"
      :key="transfer.id || `${transfer.from.id}-${transfer.to.id}`"
      class="payout-transfers__row"
      :class="{ 'payout-transfers__row--confirmed': transfer.confirmed }"
      data-test="payout-transfer"
    >
      <div class="payout-transfers__parties">
        <span class="payout-transfers__name">
          {{ transfer.from.displayName }}
        </span>
        <i class="fa-light fa-arrow-right payout-transfers__arrow" />
        <span class="payout-transfers__name">
          {{ transfer.to.displayName }}
        </span>
      </div>

      <span
        class="payout-transfers__amount"
        v-html="toUEC(Number(transfer.amount ?? 0))"
      />

      <Btn
        v-if="!preview"
        :size="BtnSizesEnum.SM"
        :variant="
          transfer.confirmed ? BtnVariantsEnum.GHOST : BtnVariantsEnum.SOLID
        "
        :loading="busyId === transfer.id"
        @click="onToggle(transfer)"
      >
        {{
          transfer.confirmed
            ? t("actions.payouts.unconfirm")
            : t("actions.payouts.confirm")
        }}
      </Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.payout-transfers {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.payout-transfers__empty {
  margin: 0;
  color: var(--color-muted, #999);
}

.payout-transfers__row {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  padding: 10px 12px;
  border: 1px solid var(--color-edge-faint, rgba(255, 255, 255, 0.08));
  border-radius: var(--radius-control-bare, 6px);
}

.payout-transfers__row--confirmed {
  border-color: var(--color-success, #4caf50);
  opacity: 0.7;
}

.payout-transfers__parties {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  flex: 1 1 auto;
  min-width: 0;
}

.payout-transfers__name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.payout-transfers__arrow {
  color: var(--color-muted, #999);
}

.payout-transfers__amount {
  font-size: 16px;
}
</style>

<script lang="ts">
export default {
  name: "PayoutsPayoutParticipantList",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
  BtnTonesEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useDestroyPayoutParticipant as useDestroyPayoutParticipantMutation,
  type PayoutParticipant,
} from "@/services/fyApi";
import type { ApiError } from "@/shared/types/api-error";

type Props = {
  payoutLedgerId: string;
  participants: PayoutParticipant[];
  manageable?: boolean;
};

const props = withDefaults(defineProps<Props>(), { manageable: false });

const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();

const busyId = ref<string | null>(null);

const destroyMutation = useDestroyPayoutParticipantMutation();

const onRemove = async (participant: PayoutParticipant) => {
  busyId.value = participant.id;

  await destroyMutation
    .mutateAsync({ payoutLedgerId: props.payoutLedgerId, id: participant.id })
    .then(() => {
      displaySuccess({ text: t("messages.payouts.participantRemoved") });
      comlink.emit("payout-ledger-changed");
    })
    .catch((error: ApiError) => {
      // The API refuses while they still hold entries, because removing them
      // would orphan those and silently move everyone else's share.
      displayAlert({
        text:
          error.response?.data?.message ??
          t("messages.payouts.participantHasEntries"),
      });
    })
    .finally(() => {
      busyId.value = null;
    });
};
</script>

<template>
  <div class="payout-participants">
    <p v-if="!participants.length" class="payout-participants__empty">
      {{ t("empty.payouts.participants") }}
    </p>

    <div
      v-for="participant in participants"
      :key="participant.id"
      class="payout-participants__row"
      data-test="payout-participant"
    >
      <span class="payout-participants__name">
        {{ participant.displayName }}
        <span v-if="participant.guest" class="payout-participants__tag">
          {{ t("labels.payouts.guest") }}
        </span>
      </span>

      <Btn
        v-if="manageable"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.BARE"
        :tone="BtnTonesEnum.DANGER"
        :loading="busyId === participant.id"
        :aria-label="t('actions.delete')"
        @click="onRemove(participant)"
      >
        <i class="fa-light fa-xmark" />
      </Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.payout-participants {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.payout-participants__empty {
  margin: 0;
  color: var(--color-muted, #999);
}

.payout-participants__row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 6px 0;
}

.payout-participants__name {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}

.payout-participants__tag {
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  padding: 1px 6px;
  border-radius: var(--radius-control-bare, 6px);
  border: 1px solid var(--color-edge-soft, rgba(255, 255, 255, 0.15));
  color: var(--color-muted, #999);
}
</style>

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
import PayoutWeightControl from "@/frontend/components/Payouts/PayoutWeightControl/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useDestroyPayoutParticipant as useDestroyPayoutParticipantMutation,
  useUpdatePayoutParticipant as useUpdatePayoutParticipantMutation,
  type PayoutParticipant,
} from "@/services/fyApi";
import type { ApiError } from "@/shared/types/api-error";

type Props = {
  payoutLedgerId: string;
  participants: PayoutParticipant[];
  manageable?: boolean;
  // How many entries each participant holds, keyed by participant id. Only
  // used to say why a row cannot be removed before the click rather than
  // after it -- the API is what actually refuses.
  entryCounts?: Record<string, number>;
};

const props = withDefaults(defineProps<Props>(), {
  manageable: false,
  entryCounts: () => ({}),
});

const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();

const busyId = ref<string | null>(null);
const weighingId = ref<string | null>(null);

const destroyMutation = useDestroyPayoutParticipantMutation();
const updateMutation = useUpdatePayoutParticipantMutation();

const entryCountFor = (participant: PayoutParticipant) =>
  props.entryCounts[participant.id] ?? 0;

const removable = (participant: PayoutParticipant) =>
  entryCountFor(participant) === 0;

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

const onWeight = async (participant: PayoutParticipant, weight: string) => {
  weighingId.value = participant.id;

  await updateMutation
    .mutateAsync({
      payoutLedgerId: props.payoutLedgerId,
      id: participant.id,
      data: { weight },
    })
    .then(() => {
      displaySuccess({ text: t("messages.payouts.weightUpdated") });
      comlink.emit("payout-ledger-changed");
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      weighingId.value = null;
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
      <div class="payout-participants__head">
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
          :disabled="!removable(participant)"
          :title="
            removable(participant)
              ? undefined
              : t('messages.payouts.participantHasEntries')
          "
          :aria-label="t('actions.delete')"
          data-test="payout-participant-remove"
          @click="onRemove(participant)"
        >
          <i class="fa-light fa-xmark" />
        </Btn>
      </div>

      <PayoutWeightControl
        v-if="manageable"
        :weight="participant.weight"
        :loading="weighingId === participant.id"
        :disabled="weighingId === participant.id"
        @update="onWeight(participant, $event)"
      />
      <span
        v-else-if="Number(participant.weight) !== 1"
        class="payout-participants__weight"
      >
        {{ participant.weight }} {{ t("labels.payouts.shares") }}
      </span>
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
  flex-direction: column;
  gap: 6px;
  padding: 8px 0;

  & + & {
    border-top: 1px solid var(--color-edge-faint, rgba(255, 255, 255, 0.08));
  }
}

.payout-participants__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
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

.payout-participants__weight {
  font-size: 12px;
  color: var(--color-gold, #d4af37);
}
</style>

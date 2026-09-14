<script lang="ts">
export default {
  name: "PayoutsPayoutLedger",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import PayoutSummary from "@/frontend/components/Payouts/PayoutSummary/index.vue";
import PayoutEntryList from "@/frontend/components/Payouts/PayoutEntryList/index.vue";
import PayoutParticipantList from "@/frontend/components/Payouts/PayoutParticipantList/index.vue";
import PayoutBalances from "@/frontend/components/Payouts/PayoutBalances/index.vue";
import PayoutTransferList from "@/frontend/components/Payouts/PayoutTransferList/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useSubscription } from "@/shared/composables/useSubscription";
import { PayoutLedgerChannel } from "@/services/fyCable/channels/PayoutLedgerChannel";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import {
  usePayoutLedger,
  usePayoutLedgerBalances,
  usePayoutEntries,
  usePayoutTransfers,
  useSettlePayoutLedger as useSettlePayoutLedgerMutation,
  useReopenPayoutLedger as useReopenPayoutLedgerMutation,
} from "@/services/fyApi";
import type { ApiError } from "@/shared/types/api-error";

type Props = {
  payoutLedgerId: string;
  // Whether the viewer may settle, reopen, and change the participant list.
  manageable?: boolean;
  // Whether the viewer may record and edit entries.
  contributable?: boolean;
  // Set for a fleet tour's ledger, whose participant list also carries whoever
  // has asked to be on it. A fleet event's ledger leaves it unset.
  tourSlug?: string;
};

const props = withDefaults(defineProps<Props>(), {
  manageable: false,
  contributable: false,
  tourSlug: undefined,
});

const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();

const ledgerId = computed(() => props.payoutLedgerId);

const { data: ledger, refetch: refetchLedger } = usePayoutLedger(ledgerId);
const { data: balances, refetch: refetchBalances } =
  usePayoutLedgerBalances(ledgerId);
const { data: entries, refetch: refetchEntries } = usePayoutEntries(ledgerId);
const { data: transfers, refetch: refetchTransfers } =
  usePayoutTransfers(ledgerId);

const settled = computed(() => ledger.value?.status === "settled");

const participants = computed(() => ledger.value?.participants ?? []);

const sessionStore = useSessionStore();

// Everyone accounts for their own money, so without the manage right the
// picker offers only the viewer's own row -- the API refuses the rest, and a
// list of names none of them may be booked against reads as a bug. A guest is
// only ever recorded for by whoever manages the ledger.
const recordableParticipants = computed(() => {
  if (props.manageable) {
    return participants.value;
  }

  return participants.value.filter(
    (participant) => participant.user?.id === sessionStore.currentUser?.id,
  );
});

// Being allowed to record money is not the same as having a row to record it
// against: a fleet's payout readers reach a tour or an event they never joined,
// and for them the picker is empty and every entry the API would accept does
// not exist. Offering the controls anyway sends them to a 403.
const canRecord = computed(
  () => props.contributable && recordableParticipants.value.length > 0,
);

// While the ledger is open the transfer list is a live preview recomputed from
// the entries; once settled it is the frozen rows people pay against.
const shownTransfers = computed(() =>
  settled.value
    ? (transfers.value ?? [])
    : ((balances.value?.transfers ?? []) as never[]),
);

// Only used to say why a participant cannot be removed before the click. The
// entries list is paginated, so on a very long ledger a participant can look
// removable when they are not -- which is exactly the behaviour this replaces,
// and the API is what refuses either way.
const entryCounts = computed(() =>
  (entries.value?.items ?? []).reduce<Record<string, number>>(
    (counts, entry) => {
      if (!entry.payoutParticipantId) {
        return counts;
      }

      counts[entry.payoutParticipantId] =
        (counts[entry.payoutParticipantId] ?? 0) + 1;

      return counts;
    },
    {},
  ),
);

const refetchAll = () => {
  void refetchLedger();
  void refetchBalances();
  void refetchEntries();
  void refetchTransfers();
};

// The channel is per-user, not per-ledger, so a viewer taking part in more than
// one ledger hears about all of them on the same stream -- hence the id check
// rather than a subscription scoped to this ledger.
useSubscription({
  channel: PayoutLedgerChannel,
  // Nothing replays what was broadcast while the socket was down, and the
  // queries do not refetch on focus, so a dropped connection would leave the
  // page showing figures that have moved on. Resyncing on every connect covers
  // the reconnects and the gap between the first fetch and the subscription
  // being live; the queries dedupe the one on mount.
  connected: refetchAll,
  received: (message) => {
    if (message?.id !== props.payoutLedgerId) {
      return;
    }

    refetchAll();
  },
});

const ledgerChangedComlink = ref();

onMounted(() => {
  ledgerChangedComlink.value = comlink.on("payout-ledger-changed", refetchAll);
});

onBeforeUnmount(() => {
  ledgerChangedComlink.value?.();
});

const onAddEntry = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Payouts/PayoutEntryModal/index.vue"),
    props: {
      payoutLedgerId: props.payoutLedgerId,
      participants: recordableParticipants.value,
    },
  });
};

const onAddParticipant = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Payouts/PayoutParticipantModal/index.vue"),
    props: { payoutLedgerId: props.payoutLedgerId },
  });
};

const settling = ref(false);

const settleMutation = useSettlePayoutLedgerMutation();
const reopenMutation = useReopenPayoutLedgerMutation();

const onSettle = async () => {
  settling.value = true;

  await settleMutation
    .mutateAsync({ id: props.payoutLedgerId })
    .then(() => {
      displaySuccess({ text: t("messages.payouts.settled") });
      refetchAll();
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      settling.value = false;
    });
};

const onReopen = async () => {
  settling.value = true;

  await reopenMutation
    .mutateAsync({ id: props.payoutLedgerId })
    .then(() => {
      displaySuccess({ text: t("messages.payouts.reopened") });
      refetchAll();
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      settling.value = false;
    });
};
</script>

<template>
  <div v-if="ledger" class="payout-ledger">
    <PayoutSummary :ledger="ledger" />

    <div class="payout-ledger__columns">
      <Panel>
        <PanelHeading>
          <div class="payout-ledger__heading">
            <span>{{ t("headlines.payouts.entries") }}</span>
            <Btn
              v-if="canRecord && !settled"
              :size="BtnSizesEnum.SM"
              data-test="payout-add-entry"
              @click="onAddEntry"
            >
              {{ t("actions.payouts.addEntry") }}
            </Btn>
          </div>
        </PanelHeading>
        <PanelBody>
          <PayoutEntryList
            :payout-ledger-id="payoutLedgerId"
            :entries="entries?.items ?? []"
            :participants="recordableParticipants"
            :editable="canRecord && !settled"
          />
        </PanelBody>
      </Panel>

      <Panel>
        <PanelHeading>
          <div class="payout-ledger__heading">
            <span>{{ t("headlines.payouts.participants") }}</span>
            <Btn
              v-if="manageable && !settled"
              :size="BtnSizesEnum.SM"
              :variant="BtnVariantsEnum.GHOST"
              data-test="payout-add-participant"
              @click="onAddParticipant"
            >
              {{ t("actions.payouts.addParticipant") }}
            </Btn>
          </div>
        </PanelHeading>
        <PanelBody>
          <PayoutParticipantList
            :payout-ledger-id="payoutLedgerId"
            :participants="participants"
            :manageable="manageable && !settled"
            :entry-counts="entryCounts"
            :tour-slug="tourSlug"
          />
        </PanelBody>
      </Panel>
    </div>

    <Panel>
      <PanelHeading>{{ t("headlines.payouts.balances") }}</PanelHeading>
      <PanelBody>
        <PayoutBalances :balances="balances?.balances ?? []" />
      </PanelBody>
    </Panel>

    <Panel>
      <PanelHeading>
        <div class="payout-ledger__heading">
          <span class="payout-ledger__heading-title">
            <span>{{ t("headlines.payouts.transfers") }}</span>
            <!-- An open ledger's list is recomputed on every read; nothing said
                 so, and it looked identical to the frozen one people pay
                 against. -->
            <span v-if="!settled" class="payout-ledger__preview">
              {{ t("labels.payouts.preview") }}
            </span>
          </span>
          <Btn
            v-if="manageable"
            :size="BtnSizesEnum.SM"
            :loading="settling"
            :confirm="
              settled
                ? t('messages.payouts.reopenConfirm')
                : t('messages.payouts.settleConfirm')
            "
            data-test="payout-settle"
            @click="settled ? onReopen() : onSettle()"
          >
            {{
              settled
                ? t("actions.payouts.reopen")
                : t("actions.payouts.settle")
            }}
          </Btn>
        </div>
      </PanelHeading>
      <PanelBody>
        <PayoutTransferList
          :payout-ledger-id="payoutLedgerId"
          :transfers="shownTransfers"
          :preview="!settled"
        />
      </PanelBody>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
.payout-ledger {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.payout-ledger__columns {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 16px;

  @media (min-width: 992px) {
    grid-template-columns: minmax(0, 2fr) minmax(0, 1fr);
  }
}

.payout-ledger__heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  width: 100%;
}

.payout-ledger__heading-title {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.payout-ledger__preview {
  font-family: "Open Sans", sans-serif;
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--color-gold, #d4af37);
}
</style>

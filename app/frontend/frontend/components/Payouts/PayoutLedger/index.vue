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
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
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
};

const props = withDefaults(defineProps<Props>(), {
  manageable: false,
  contributable: false,
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

// While the ledger is open the transfer list is a live preview recomputed from
// the entries; once settled it is the frozen rows people pay against.
const shownTransfers = computed(() =>
  settled.value
    ? (transfers.value ?? [])
    : ((balances.value?.transfers ?? []) as never[]),
);

const refetchAll = () => {
  void refetchLedger();
  void refetchBalances();
  void refetchEntries();
  void refetchTransfers();
};

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
      participants: participants.value,
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
              v-if="contributable && !settled"
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
            :participants="participants"
            :editable="contributable && !settled"
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
          <span>{{ t("headlines.payouts.transfers") }}</span>
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
</style>

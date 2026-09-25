<script lang="ts">
export default {
  name: "FleetContractPayoutsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import DetailSkeleton from "@/shared/components/DetailSkeleton/index.vue";
import PayoutLedger from "@/frontend/components/Payouts/PayoutLedger/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import { checkAccess } from "@/shared/utils/Access";
import {
  type Fleet,
  FleetContractStateEnum,
  useFleetContract,
  useFleetContractPayoutLedger,
  useCreateFleetContractPayoutLedger as useCreateFleetContractPayoutLedgerMutation,
} from "@/services/fyApi";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";
import type { ApiError } from "@/shared/types/api-error";

type Props = {
  fleet: Fleet;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();
const sessionStore = useSessionStore();
const { displayAlert } = useAppNotifications();

const fleetSlug = computed(() => props.fleet.slug);
const contractSlug = computed(() => String(route.params.contract));

const { data: contract } = useFleetContract(fleetSlug, contractSlug);

const {
  data: ledger,
  refetch,
  isLoading: ledgerLoading,
} = useFleetContractPayoutLedger(
  fleetSlug,
  contractSlug,
  // A 404 here is the normal "no ledger opened yet" state, not an error worth
  // retrying or reporting.
  { query: { retry: false } },
);

// The author is the client, and reviews what the contractors claim whether or
// not they also run the fleet's contracts -- the same rule the API applies.
const isAuthor = computed(
  () =>
    !!contract.value?.createdBy &&
    contract.value.createdBy.id === sessionStore.currentUser?.id,
);

const canManage = computed(
  () =>
    isAuthor.value ||
    checkAccess(props.resourceAccess, [
      "fleet:manage",
      "fleet:contracts:manage",
    ]),
);

const canOpen = computed(
  () =>
    canManage.value &&
    contract.value?.state === FleetContractStateEnum.FULFILLED,
);

const opening = ref(false);

const createMutation = useCreateFleetContractPayoutLedgerMutation();

const onOpenLedger = async () => {
  opening.value = true;

  await createMutation
    .mutateAsync({
      fleetSlug: fleetSlug.value,
      fleetContractSlug: contractSlug.value,
      data: {},
    })
    .then(() => {
      void refetch();
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      opening.value = false;
    });
};

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: fleetSlug.value } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-contracts", params: { slug: fleetSlug.value } },
    label: t("headlines.fleets.contracts.index"),
  },
  {
    to: {
      name: "fleet-contract",
      params: { slug: fleetSlug.value, contract: contractSlug.value },
    },
    label: contract.value?.title ?? t("nav.fleets.contracts.index"),
  },
]);
</script>

<template>
  <section>
    <BreadCrumbs :crumbs="crumbs" />

    <Heading>{{ t("headlines.payouts.index") }}</Heading>

    <DetailSkeleton
      v-if="ledgerLoading"
      :hero="false"
      :figures="4"
      :panels="3"
    />

    <Panel v-else-if="!ledger">
      <PanelBody>
        <p class="fleet-contract-payouts__empty">
          {{
            canOpen
              ? t("texts.payouts.contractReady")
              : t("texts.payouts.contractNotReady")
          }}
        </p>
        <Btn
          v-if="canOpen"
          :loading="opening"
          :size="BtnSizesEnum.LG"
          data-test="payout-open-ledger"
          @click="onOpenLedger"
        >
          {{ t("actions.payouts.openLedger") }}
        </Btn>
      </PanelBody>
    </Panel>

    <PayoutLedger
      v-else
      :payout-ledger-id="ledger.id"
      :manageable="canManage"
      contributable
      :expenses-allowed="contract?.reimburseExpenses ?? true"
    />
  </section>
</template>

<style lang="scss" scoped>
.fleet-contract-payouts__empty {
  color: var(--color-text-dim, #959595);
  margin-bottom: 16px;
}
</style>

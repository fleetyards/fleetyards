<script lang="ts">
export default {
  name: "FleetContractEditPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import ContractForm from "@/frontend/components/Fleets/Contracts/ContractForm/index.vue";
import ContractItemsForm from "@/frontend/components/Fleets/Contracts/ContractItemsForm/index.vue";
import {
  type Fleet,
  type FleetMember,
  FleetContractStateEnum,
  useFleetContract,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useRouter } from "vue-router";
import { useContractEditAccess } from "@/frontend/composables/useContractEditAccess";
import { useSessionStore } from "@/frontend/stores/session";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const sessionStore = useSessionStore();

const fleetSlug = computed(() => props.fleet.slug);
const contractSlug = computed(() => route.params.contract as string);

const { data: contract, refetch } = useFleetContract(fleetSlug, contractSlug);

const mayEdit = useContractEditAccess(
  () => contract.value,
  () => props.resourceAccess,
);

const editable = computed(
  () => contract.value?.state === FleetContractStateEnum.DRAFT && mayEdit.value,
);

// Only a draft is editable -- published, the terms are what somebody claimed
// the contract on -- and only by whoever may change it. The route lets every
// reader through, since a member edits their own personal contract; reached
// by its URL anyway, the page hands back to the contract rather than offering
// a form the API would refuse. Decided only once both the contract and the
// signed-in user are known, so an author is not sent away before the session
// has said who they are.
watch(
  [contract, () => sessionStore.currentUser],
  ([value, user]) => {
    if (!value || !user || editable.value) return;

    void router.replace({
      name: "fleet-contract",
      params: { slug: props.fleet.slug, contract: contractSlug.value },
    });
  },
);

const cancel = () => {
  void router.push({
    name: "fleet-contract",
    params: { slug: props.fleet.slug, contract: contractSlug.value },
  });
};

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-contracts", params: { slug: props.fleet.slug } },
    label: t("headlines.fleets.contracts.index"),
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading size="hero" hero>
    {{ t("headlines.fleets.contracts.edit") }}
  </Heading>

  <template v-if="contract && editable">
    <!-- The lines live on a saved contract, so they are edited here rather than
         in the create form: publishing refuses a contract with nothing to
         deliver, which is what sends an author here. -->
    <ContractForm :fleet="fleet" :contract="contract" @cancel="cancel">
      <template #sections>
        <ContractItemsForm
          :fleet="fleet"
          :contract="contract"
          :kind="contract.kind"
          @changed="refetch()"
        />
      </template>
    </ContractForm>
  </template>
</template>

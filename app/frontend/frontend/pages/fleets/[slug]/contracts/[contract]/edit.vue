<script lang="ts">
export default {
  name: "FleetContractEditPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import ContractForm from "@/frontend/components/Fleets/Contracts/ContractForm/index.vue";
import ContractItemsForm from "@/frontend/components/Fleets/Contracts/ContractItemsForm/index.vue";
import {
  type Fleet,
  type FleetMember,
  useFleetContract,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const fleetSlug = computed(() => props.fleet.slug);
const contractSlug = computed(() => route.params.contract as string);

const { data: contract, refetch } = useFleetContract(fleetSlug, contractSlug);

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

  <template v-if="contract">
    <!-- The lines live on a saved contract, so they are edited here rather than
         in the create form: publishing refuses a contract with nothing to
         deliver, which is what sends an author here. -->
    <ContractForm :fleet="fleet" :contract="contract" @cancel="cancel">
      <template #sections>
        <Panel>
          <PanelBody>
            <Heading>{{ t("headlines.fleets.contracts.items") }}</Heading>

            <ContractItemsForm
              :fleet="fleet"
              :contract="contract"
              @changed="refetch()"
            />
          </PanelBody>
        </Panel>
      </template>
    </ContractForm>
  </template>
</template>

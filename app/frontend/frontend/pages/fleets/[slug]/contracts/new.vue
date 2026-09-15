<script lang="ts">
export default {
  name: "FleetContractNewPage",
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
  type FleetContractItemInput,
  FleetContractKindEnum,
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
const router = useRouter();

// Held here until the contract they belong to exists; the form sends both in
// one request.
const items = ref<FleetContractItemInput[]>([]);
const kind = ref<FleetContractKindEnum>(FleetContractKindEnum.PROCUREMENT);

const cancel = () => {
  void router.push({
    name: "fleet-contracts",
    params: { slug: props.fleet.slug },
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
    {{ t("headlines.fleets.contracts.create") }}
  </Heading>

  <ContractForm
    :fleet="fleet"
    :items="items"
    @cancel="cancel"
    @kind-change="kind = $event"
  >
    <template #sections>
      <ContractItemsForm
        :fleet="fleet"
        :kind="kind"
        :drafts="items"
        @update:drafts="items = $event"
      />
    </template>
  </ContractForm>
</template>

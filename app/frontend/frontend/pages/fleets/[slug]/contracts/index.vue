<script lang="ts">
export default {
  name: "FleetContractsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import ContractBoard from "@/frontend/components/Fleets/Contracts/ContractBoard/index.vue";
import { type Fleet, type FleetMember } from "@/services/fyApi";
import { contractBoardViewFrom } from "@/frontend/components/Fleets/Contracts/ContractBoard/views";
import { useI18n } from "@/shared/composables/useI18n";
import { checkAccess } from "@/shared/utils/Access";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();

const route = useRoute();

// One page, four boards. Which one is the route, the way the logistics ledger
// and the transfers list do it, so each of them can be linked to.
const view = computed(() => contractBoardViewFrom(route.name));

const canCreate = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:contracts:manage",
    "fleet:contracts:create",
  ]),
);

const goToCreate = () => {
  void router.push({
    name: "fleet-contract-new",
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

const heading = computed(() =>
  t(`headlines.fleets.contracts.views.${view.value.key}`),
);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading size="hero" hero>
    {{ heading }}
  </Heading>

  <Teleport v-if="canCreate" to="#header-right">
    <Btn
      :size="BtnSizesEnum.MD"
      :aria-label="t('actions.fleets.contracts.create')"
      data-test="create-contract"
      mobile-icon-only
      @click="goToCreate"
    >
      <i class="fa-duotone fa-plus" />
      {{ t("actions.fleets.contracts.create") }}
    </Btn>
  </Teleport>

  <ContractBoard :fleet="fleet" :view="view" />
</template>

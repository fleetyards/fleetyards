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
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();

const route = useRoute();

// One page, four boards. The choice lives in the query, so a board can be
// linked to without the page being thrown away and rebuilt each time somebody
// switches -- `App.vue` keys the page on its path.
const view = computed(() => contractBoardViewFrom(route.query.view));

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

// One route now, so the document title is this page's to write and it follows
// the board rather than naming one of four.
const { updateMetaInfo } = useMetaInfo();

watch(heading, (value) => updateMetaInfo({ title: value }), {
  immediate: true,
});
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

<script lang="ts">
export default {
  name: "FleetToursPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import ToursTable from "@/frontend/components/Payouts/ToursTable/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { checkAccess } from "@/shared/utils/Access";
import { useFleetTours } from "@/services/fyApi";
import type { Fleet, Tour } from "@/services/fyApi";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";

type Props = {
  fleet: Fleet;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const router = useRouter();

const fleetSlug = computed(() => props.fleet.slug);

const { data: tours, isLoading } = useFleetTours(fleetSlug);

const canCreate = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:payouts:manage",
    "fleet:payouts:create",
  ]),
);

const onRowClick = (tour: Tour) => {
  void router.push({
    name: "fleet-tour",
    params: { slug: props.fleet.slug, tour: tour.slug },
  });
};

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  { label: t("nav.fleets.tours") },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading size="hero" hero>
    {{ t("headlines.payouts.tours.index") }}
  </Heading>

  <Teleport to="#header-right">
    <Btn
      v-if="canCreate"
      :size="BtnSizesEnum.MD"
      :to="{ name: 'fleet-tour-new', params: { slug: props.fleet.slug } }"
      :aria-label="t('actions.payouts.createTour')"
      data-test="fleet-tour-add"
      mobile-icon-only
    >
      <i class="fa-light fa-plus" />
      <span>{{ t("actions.payouts.createTour") }}</span>
    </Btn>
  </Teleport>

  <ToursTable
    :tours="tours?.items ?? []"
    :loading="isLoading"
    @row-click="onRowClick"
  />
</template>

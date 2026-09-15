<script lang="ts">
export default {
  name: "FleetTourPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import DetailSkeleton from "@/shared/components/DetailSkeleton/index.vue";
import TourDetails from "@/frontend/components/Payouts/TourDetails/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { checkAccess } from "@/shared/utils/Access";
import { useFleetTour } from "@/services/fyApi";
import type { Fleet } from "@/services/fyApi";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";

type Props = {
  fleet: Fleet;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();
const route = useRoute();

const fleetSlug = computed(() => props.fleet.slug);
const tourSlug = computed(() => String(route.params.tour));

const { data: tour, refetch, isLoading } = useFleetTour(fleetSlug, tourSlug);

// TourDetails adds the organiser on top of this; a fleet's payout managers get
// it without having organised or joined the tour.
const canManage = computed(() =>
  checkAccess(props.resourceAccess, ["fleet:manage", "fleet:payouts:manage"]),
);

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-tours", params: { slug: props.fleet.slug } },
    label: t("nav.fleets.tours"),
  },
  // Dropped rather than left blank while the tour loads: an empty crumb is a
  // separator with nothing after it.
  ...(tour.value ? [{ label: tour.value.title }] : []),
]);

const { updateMetaInfo } = useMetaInfo({ custom: true });

watch(
  () => tour.value?.title,
  (title) => {
    if (title) {
      updateMetaInfo({ title });
    }
  },
  { immediate: true },
);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <template v-if="tour">
    <Heading size="hero" hero>{{ tour.title }}</Heading>

    <TourDetails :tour="tour" :manageable="canManage" @reload="refetch" />
  </template>

  <!-- No hero: a tour opens on its title and the ledger's four figures, not on
       a cover. The panels below stand in for the ledger's entry, participant
       and transfer lists. -->
  <DetailSkeleton
    v-else-if="isLoading"
    :hero="false"
    :figures="4"
    :panels="3"
  />
</template>

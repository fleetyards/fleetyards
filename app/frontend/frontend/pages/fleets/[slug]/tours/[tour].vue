<script lang="ts">
export default {
  name: "FleetTourPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
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

const { data: tour } = useFleetTour(fleetSlug, tourSlug);

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
  { label: tour.value?.title ?? "" },
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
  <template v-if="tour">
    <BreadCrumbs :crumbs="crumbs" />

    <Heading size="hero" hero>{{ tour.title }}</Heading>

    <TourDetails :tour="tour" :manageable="canManage" />
  </template>
</template>

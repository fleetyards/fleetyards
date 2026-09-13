<script lang="ts">
export default {
  name: "FleetLogisticsTransfersPage",
};
</script>

<script lang="ts" setup>
import type { Crumb } from "@/shared/components/BreadCrumbs/types";
import TransfersView from "@/frontend/components/Logistics/TransfersView/index.vue";
import { type Fleet, type FleetMember } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

// Handed down by `logistics.vue`, which also gates the branch on
// `fleet_logistics` -- so this never renders for a fleet that cannot use it.
type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-logistics", params: { slug: props.fleet.slug } },
    label: t("nav.fleets.logistics.index"),
  },
]);
</script>

<template>
  <TransfersView
    :crumbs="crumbs"
    :fleet-slug="fleet.slug"
    incoming-route="fleet-logistics-transfers"
    outgoing-route="fleet-logistics-transfers-outgoing"
  />
</template>

<script lang="ts">
export default {
  name: "HomeDashboardContractsPanel",
};
</script>

<script lang="ts" setup>
import FleetContractsPanel from "@/frontend/components/Fleets/Dashboard/ContractsPanel/index.vue";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import { useFleet, useMyFleetSummaries } from "@/services/fyApi";
import { primaryFleet } from "@/frontend/components/Home/Dashboard/primaryFleet";

// The fleet card's fleet, and its board only where the fleet runs one: a
// pilot's work in hand first, then what is open for pickup.
const { data: summaries } = useMyFleetSummaries({ query: liveQuery });

const summary = computed(() => primaryFleet(summaries.value?.items || []));

const slug = computed(() =>
  summary.value?.contractsEnabled ? summary.value.slug : "",
);

const { data: fleet } = useFleet(slug, {
  query: { enabled: computed(() => !!slug.value) },
});
</script>

<template>
  <FleetContractsPanel v-if="slug && fleet" :fleet="fleet" />
</template>

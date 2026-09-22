<script lang="ts">
export default {
  name: "FleetStatsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import FleetStats from "@/frontend/components/Fleets/FleetStats/index.vue";
import SquadronFilter from "@/frontend/components/Fleets/Squadrons/SquadronFilter/index.vue";
import PublicFleetStats from "@/frontend/components/Fleets/PublicFleetStats/index.vue";
import { type Fleet, type FleetMember } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  fleet: Fleet;
  membership?: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

const crumbs = computed<Crumb[]>(() => {
  if (!props.fleet) {
    return [];
  }

  return [
    {
      to: {
        name: "fleet",
        params: {
          slug: props.fleet.slug,
        },
      },
      label: props.fleet.name,
    },
  ];
});
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Heading size="hero" hero>{{ t(`headlines.${route.meta.title}`) }}</Heading>

  <!-- Above the figures, the same place the roster and the ship list put it.
       The control writes the route query; every figure on the page reads it. -->
  <SquadronFilter
    v-if="membership"
    :fleet="fleet"
    class="stats-squadron-filter"
  />

  <FleetStats v-if="membership" :fleet="fleet" />

  <PublicFleetStats v-else-if="fleet.publicFleetStats" :fleet="fleet" />
</template>

<style lang="scss" scoped>
.stats-squadron-filter {
  margin-bottom: 20px;
}
</style>

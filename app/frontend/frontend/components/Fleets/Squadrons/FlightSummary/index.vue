<script lang="ts">
export default {
  name: "FleetSquadronFlightSummary",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { useI18n } from "@/shared/composables/useI18n";
import type { FleetSquadronFlight } from "@/services/fyApi";

type Props = {
  flight: FleetSquadronFlight;
  to: RouteLocationRaw;
};

const props = defineProps<Props>();

const { t } = useI18n();

const slotCount = computed(
  () =>
    props.flight.slots.length +
    props.flight.ships.reduce(
      (sum, ship) => sum + (ship.slots?.length ?? 0),
      0,
    ),
);

const counts = computed(() => [
  {
    value: props.flight.ships.length,
    label: t("headlines.fleets.missions.ships"),
  },
  { value: slotCount.value, label: t("headlines.fleets.missions.slots") },
]);
</script>

<template>
  <Panel
    :variant="PanelVariantsEnum.SLIM"
    class="flight-summary"
    :data-test="`flight-summary-${flight.id}`"
    fill-height
  >
    <PanelHeading compact divider :level="HeadingLevelEnum.H3">
      <template #default>
        <router-link :to="to">{{ flight.name }}</router-link>
      </template>
    </PanelHeading>
    <PanelBody class="flight-summary__body" rounded="bottom">
      <div
        v-for="count in counts"
        :key="count.label"
        class="flight-summary__count"
      >
        <span class="flight-summary__count-number">{{ count.value }}</span>
        <span class="flight-summary__count-label">{{ count.label }}</span>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.flight-summary__body {
  display: flex;
  flex: 1;
  align-items: center;
  gap: 24px;
  padding: 14px 16px;
}

.flight-summary__count {
  display: flex;
  align-items: baseline;
  gap: 6px;
}

.flight-summary__count-number {
  font-size: 1.5em;
  line-height: 1;
}

.flight-summary__count-label {
  color: var(--color-text-dim);
  font-size: 0.85em;
}
</style>

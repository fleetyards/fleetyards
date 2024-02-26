<template>
  <dl v-if="station" class="row">
    <dt class="col-sm-4 text-sm-right">{{ t("labels.station.type") }}:</dt>
    <dd class="col-sm-8">{{ station.typeLabel }}</dd>

    <dt class="col-sm-4 text-sm-right">{{ t("labels.station.location") }}:</dt>
    <dd class="col-sm-8">
      <LocationLabel :station="station" />
    </dd>

    <dt v-if="station.shopListLabel" class="col-sm-4 text-right">
      {{ t("labels.station.shops") }}:
    </dt>
    <dd v-if="station.shopListLabel" class="col-sm-8">
      {{ station.shopListLabel }}
    </dd>

    <template v-if="station.dockCounts?.length">
      <dt class="col-sm-4 text-sm-right">{{ t("labels.station.docks") }}:</dt>
      <dd class="col-sm-8">
        <ul class="list-unstyled">
          <li v-for="(dock, index) in station.dockCounts" :key="index">
            {{ dock.size }} {{ dock.typeLabel }}: {{ dock.count }}
          </li>
        </ul>
      </dd>
    </template>

    <template v-if="station.habitationCounts?.length">
      <dt class="col-sm-4 text-sm-right">
        {{ t("labels.station.habitation") }}:
      </dt>
      <dd class="col-sm-8">
        <ul class="list-unstyled">
          <li
            v-for="(habitation, index) in station.habitationCounts"
            :key="index"
          >
            {{ habitation.typeLabel }}: {{ habitation.count }}
          </li>
        </ul>
      </dd>
    </template>
  </dl>
</template>

<script lang="ts" setup>
import LocationLabel from "@/frontend/components/Stations/LocationLabel/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import type { Station } from "@/services/fyApi";

const { t } = useI18n();

type Props = {
  station: Station;
};

defineProps<Props>();
</script>

<script lang="ts">
export default {
  name: "StationsListStats",
};
</script>

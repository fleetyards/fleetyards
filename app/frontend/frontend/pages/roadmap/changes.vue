<script lang="ts">
export default {
  name: "RoadmapChangesPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { useRoadmapQueries } from "@/frontend/composables/useRoadmapQueries";
import RoadmapList from "@/frontend/components/Roadmap/List/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useSubscription,
  ChannelsEnum,
} from "@/shared/composables/useSubscription";
import { type FilterOption } from "@/services/fyApi";

const { changesQuery, weeksFilterQuery } = useRoadmapQueries();

const { data: weekOptions } = weeksFilterQuery();

const selectedWeek = ref(0);

const filters = computed(() => {
  if (!weekOptions || !weekOptions.value) {
    return undefined;
  }

  return weekOptions.value[selectedWeek.value].query;
});

const { data, refetch, ...asyncStatus } = changesQuery(filters, {
  enabled: !!filters.value,
});

watch(
  () => filters.value,
  () => {
    refetch();
  },
);

useSubscription({
  channelName: ChannelsEnum.ROADMAP,
  received: () => refetch(),
});

const filterOptions = computed(() => {
  if (!weekOptions.value) {
    return [];
  }

  return weekOptions.value as unknown as FilterOption[];
});

const { t } = useI18n();

const crumbs = computed(() => {
  return [
    {
      to: {
        name: "roadmap",
      },
      label: t("nav.roadmap.index"),
    },
  ];
});
</script>

<template>
  <div class="row">
    <div class="col-12">
      <BreadCrumbs :crumbs="crumbs" />
      <h1 class="sr-only">
        {{ t("headlines.roadmap") }}
      </h1>
    </div>
  </div>

  <Teleport to="#header-actions">
    <Btn href="https://robertsspaceindustries.com/roadmap">
      {{ t("labels.rsiRoadmap") }}
    </Btn>
  </Teleport>

  <div class="row">
    <div class="col-12 col-lg-6">
      <FilterGroup
        v-model="selectedWeek"
        :label="t('labels.roadmap.selectWeek')"
        name="query"
        :options="filterOptions"
        label-attr="label"
        :nullable="false"
        :no-label="true"
        @input="refetch"
      />
    </div>
  </div>

  <hr class="dark" />

  <RoadmapList
    name="roadmap-changes"
    :records="data || []"
    :async-status="asyncStatus"
  />
</template>

<script lang="ts">
export default {
  name: "RoadmapChangesPage",
};
</script>

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import RoadmapItem from "@/frontend/components/Roadmap/RoadmapItem/index.vue";
import EmptyBox from "@/shared/components/EmptyBox/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";

const { changesQuery } = useRoadmapQueries();

const { data, refetch, ...asyncStatus } = changesQuery(filters);

// loading = true;

const compact = ref(false);

// roadmapChanges = [];

// options = [];

const roadmapChannel = ref();

// selectedWeek = 0;

// get toggleCompactTooltip() {
//   if (this.compact) {
//     return this.$t("actions.showDetails");
//   }

//   return this.$t("actions.hideDetails");
// }

// get emptyBoxVisible() {
//   return !this.loading && this.roadmapChanges.length === 0;
// }

// get query() {
//   if (!this.options.length) {
//     return null;
//   }

//   return this.options[this.selectedWeek].query;
// }

const groupedByRelease = computed(() => {
  return this.roadmapChanges.reduce((rv, x) => {
    const value = JSON.parse(JSON.stringify(rv));

    value[x.release] = rv[x.release] || [];
    value[x.release].push(x);

    return value;
  }, {});
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

onMounted(() => {
  setupUpdates();
});

onUnmounted(() => {
  if (roadmapChannel.value) {
    roadmapChannel.value.unsubscribe();
  }
});

const setupUpdates = () => {
  if (roadmapChannel.value) {
    roadmapChannel.value.unsubscribe();
  }

  roadmapChannel.value = cable.consumer.subscriptions.create(
    {
      channel: "RoadmapChannel",
    },
    {
      received: refetch,
    },
  );
};

const toggleCompact = () => {
  compact.value = !compact.value;
};

// async fetchOptions() {
//   const response = await this.$api.get("roadmap/weeks");

//   if (!response.error) {
//     this.options = response.data;
//   }
// }

// async fetch() {
//   if (!this.query) {
//     return;
//   }

//   this.loading = true;
//   const response = await this.$api.get("roadmap?changes=1", {
//     q: this.query,
//   });

//   this.loading = false;

//   if (!response.error) {
//     this.roadmapChanges = response.data.filter((item) => item.lastVersion);
//   }
// }
</script>

<template>
  <section class="container roadmap">
    <div class="row">
      <div class="col-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1 class="sr-only">
          {{ t("headlines.roadmap") }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-lg-6">
        <FilterGroup
          v-model="selectedWeek"
          :label="t('labels.roadmap.selectWeek')"
          name="query"
          :options="options"
          label-attr="label"
          :nullable="false"
          :no-label="true"
          @input="fetch"
        />
      </div>
      <div class="col-12 col-lg-6">
        <div class="page-actions page-actions-right">
          <Btn href="https://robertsspaceindustries.com/roadmap">
            {{ t("labels.rsiRoadmap") }}
          </Btn>
        </div>
      </div>
    </div>
    <hr class="dark" />

    <FilteredList
      name="roadmapChanges"
      :records="data || []"
      :async-status="asyncStatus"
    >
      <template #default> foo </template>
    </FilteredList>
    <div class="row">
      <div class="col-12">
        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="(items, release) in groupedByRelease"
            :key="`releases-${release}`"
            class="col-12 fade-list-item release"
          >
            <h2>
              <span class="title">{{ release }}</span>
              <span v-if="items[0].releaseDescription" class="released-label">
                ({{ items[0].releaseDescription }})
              </span>
              <small class="text-muted">
                {{ t("labels.roadmap.stories", { count: items.length }) }}
              </small>
            </h2>

            <div class="row">
              <div
                v-for="item in items"
                :key="item.id"
                class="col-12 col-lg-6 col-xl-4 col-xxl-2dot4 fade-list-item"
              >
                <RoadmapItem :item="item" :compact="false" />
              </div>
            </div>
          </div>
        </transition-group>
        <EmptyBox :visible="emptyBoxVisible" />
        <Loader :loading="loading" :fixed="true" />
      </div>
    </div>
  </section>
</template>

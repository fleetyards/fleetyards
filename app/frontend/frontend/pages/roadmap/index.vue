<script lang="ts">
export default {
  name: "RoadmapPage",
};
</script>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import RoadmapItem from "@/frontend/components/Roadmap/RoadmapItem/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useSubscription,
  ChannelsEnum,
} from "@/shared/composables/useSubscription";
import type { RoadmapItem as TRoadmapItem } from "@/services/fyApi";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useRoadmapQueries } from "@/frontend/composables/useRoadmapQueries";
import FilteredList from "@/shared/components/FilteredList/index.vue";

const { t } = useI18n();

const released = ref(false);

const showRemoved = ref(false);

const visible = ref<string[]>([]);

const releasedToggleLabel = computed(() => {
  if (released.value) {
    return t("actions.hideReleased");
  }

  return t("actions.showReleased");
});

const toggleRemovedTooltip = computed(() => {
  if (showRemoved.value) {
    return t("actions.roadmap.hideRemoved");
  }

  return t("actions.roadmap.showRemoved");
});

const groupedByRelease = computed(() =>
  data.value?.reduce(
    (rv, x) => {
      const value = JSON.parse(JSON.stringify(rv));

      value[x.release] = rv[x.release] || [];
      value[x.release].push(x);

      return value;
    },
    {} as Record<string, TRoadmapItem[]>,
  ),
);

watch(
  () => released.value,
  () => {
    refetch();
  },
);

const toggleReleased = () => {
  released.value = !released.value;
};

const togglerShowRemoved = () => {
  showRemoved.value = !showRemoved.value;

  refetch();
};

const toggle = (release: string) => {
  if (visible.value.includes(release)) {
    const index = visible.value.indexOf(release);

    visible.value.splice(index, 1);

    return null;
  }

  return visible.value.push(release);
};

const openReleased = () => {
  if (!groupedByRelease.value) {
    return undefined;
  }

  const releases = Object.keys(groupedByRelease.value);

  releases.forEach((release) => {
    const items = groupedByRelease.value![release];

    if (items.length && !items[0].released) {
      visible.value.push(release);
    }
  });
};

const { listQuery } = useRoadmapQueries();

const filters = computed(() => {
  return {
    releasedEq: released.value,
    activeIn: [true, !showRemoved.value],
  };
});

const { data, refetch, ...asyncStatus } = listQuery(filters);

useSubscription({
  channelName: ChannelsEnum.ROADMAP,
  received: () => refetch(),
});

onMounted(() => {
  openReleased();
});

watch(
  () => data.value,
  () => {
    openReleased();
  },
);
</script>

<template>
  <section class="container roadmap">
    <div class="row">
      <div class="col-12">
        <h1 class="sr-only">
          {{ t("headlines.roadmap") }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <div class="page-actions page-actions-right">
          <Btn
            :to="{ name: 'roadmap-changes' }"
            data-test="nav-roadmap-changes"
          >
            <i class="fad fa-tasks" />
            <span>{{ t("nav.roadmap.changes") }}</span>
          </Btn>
          <Btn :to="{ name: 'roadmap-ships' }" data-test="nav-roadmap-ships">
            <i class="fad fa-starship" />
            <span>{{ t("nav.roadmap.ships") }}</span>
          </Btn>
          <Btn href="https://robertsspaceindustries.com/roadmap">
            {{ t("labels.rsiRoadmap") }}
          </Btn>
        </div>
      </div>
    </div>

    <div class="row">
      <div class="col-3"></div>
      <div class="col-6">
        <div class="text-center">
          <a class="show-released" @click="toggleReleased">
            - {{ releasedToggleLabel }} -
          </a>
        </div>
      </div>
      <div class="col-3">
        <div class="d-flex justify-content-end">
          <BtnDropdown :size="BtnSizesEnum.SMALL">
            <Btn
              :size="BtnSizesEnum.SMALL"
              :active="showRemoved"
              :aria-label="toggleRemovedTooltip"
              @click="togglerShowRemoved"
            >
              <span v-if="showRemoved">
                <i class="fad fa-eye-slash"></i>
              </span>
              <span v-else>
                <i class="fad fa-eye"></i>
              </span>
              <span>{{ toggleRemovedTooltip }}</span>
            </Btn>
          </BtnDropdown>
        </div>
      </div>
    </div>

    <FilteredList
      name="roadmap"
      :records="data || []"
      :async-status="asyncStatus"
    >
      <template #default>
        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="(items, release) in groupedByRelease"
            :key="`releases-${release}`"
            class="col-12 fade-list-item release"
          >
            <h2
              :class="{
                open: visible.includes(String(release)),
              }"
              class="toggleable"
              @click="toggle(String(release))"
            >
              <span class="title">{{ release }}</span>
              <span v-if="items[0].releaseDescription" class="released-label">
                ({{ items[0].releaseDescription }})
              </span>
              <small class="text-muted">
                {{ t("labels.roadmap.stories", { count: items.length }) }}
              </small>
              <i class="fa fa-chevron-right" />
            </h2>

            <Collapsed
              :id="`${release}-cards`"
              :visible="visible.includes(String(release))"
            >
              <div class="row">
                <div
                  v-for="item in items"
                  :key="item.id"
                  class="col-12 col-lg-6 col-xl-4 col-xxl-2dot4 fade-list-item"
                >
                  <RoadmapItem :item="item" />
                </div>
              </div>
            </Collapsed>
          </div>
        </transition-group>
      </template>
    </FilteredList>
  </section>
</template>

<style lang="scss" scoped>
@import "index";
</style>

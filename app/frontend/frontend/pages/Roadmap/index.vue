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
            {{ t("nav.roadmap.changes") }}
          </Btn>
          <Btn :to="{ name: 'roadmap-ships' }" data-test="nav-roadmap-ships">
            <i class="fad fa-starship" />
            {{ t("nav.roadmap.ships") }}
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
          <BtnDropdown size="small">
            <Btn
              size="small"
              variant="dropdown"
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
    <div class="row">
      <div class="col-12">
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
        <EmptyBox :visible="emptyBoxVisible" />
        <Loader :loading="isLoading || isFetching" :fixed="true" />
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import RoadmapItem from "@/frontend/components/Roadmap/RoadmapItem/index.vue";
import EmptyBox from "@/shared/components/EmptyBox/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { Subscription } from "@rails/actioncable";
import { useI18n } from "@/frontend/composables/useI18n";
import { useCable } from "@/shared/composables/useCable";
import type { RoadmapItem as TRoadmapItem } from "@/services/fyApi";
import { useQuery } from "@tanstack/vue-query";
import { useApiClient } from "@/frontend/composables/useApiClient";

const { t, currentLocale } = useI18n();

const released = ref(false);

const showRemoved = ref(false);

const visible = ref<string[]>([]);

const roadmapChannel = ref<Subscription | null>(null);

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

const emptyBoxVisible = computed(
  () => !isLoading.value && data.value?.length === 0,
);

const groupedByRelease = computed(
  () =>
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

onMounted(() => {
  setupUpdates();
});

onUnmounted(() => {
  if (roadmapChannel.value) {
    roadmapChannel.value.unsubscribe();
  }
});

watch(
  () => released.value,
  () => {
    refetch();
  },
);

const cable = useCable();

const setupUpdates = () => {
  if (roadmapChannel.value) {
    roadmapChannel.value.unsubscribe();
  }

  roadmapChannel.value = cable.consumer.subscriptions.create(
    {
      channel: "RoadmapChannel",
    },
    {
      received: fetch,
    },
  );
};

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

const { roadmap: roadmapService } = useApiClient();

const { isLoading, isFetching, data, refetch, status } = useQuery({
  queryKey: ["roadmap-items"],
  queryFn: () =>
    roadmapService.roadmapItems({
      q: {
        releasedEq: released.value,
        activeIn: [true, !showRemoved.value],
      },
    }),
});

watch(
  () => status.value,
  () => {
    if (status.value === "success") {
      openReleased();
    }
  },
);
</script>

<script lang="ts">
export default {
  name: "RoadmapPage",
};
</script>

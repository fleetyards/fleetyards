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
      <div class="col-12">
        <div class="page-actions page-actions-right">
          <Btn
            :active="!compact"
            :aria-label="toggleCompactTooltip"
            @click.native="toggleCompact"
          >
            {{ toggleCompactTooltip }}
          </Btn>
          <Btn href="https://robertsspaceindustries.com/roadmap">
            {{ t("labels.rsiRoadmap") }}
          </Btn>
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
                {{ t("labels.roadmap.ships", { count: String(items.length) }) }}
              </small>
              <i class="fa fa-chevron-right" />
            </h2>

            <div
              :id="`${release}-cards`"
              v-show-slide:400:ease-in-out="visible.includes(String(release))"
            >
              <div class="row">
                <div
                  v-for="item in items"
                  :key="item.id"
                  class="col-12 col-lg-6 col-xl-4 col-xxl-2dot4 fade-list-item"
                >
                  <RoadmapItem :item="item" :compact="compact" />
                </div>
              </div>
            </div>
          </div>
        </transition-group>
        <EmptyBox :visible="emptyBoxVisible" />
        <Loader :loading="loading" :fixed="true" />
        <div class="row">
          <div class="col-12 fade-list-item release">
            <h2
              :class="{
                open: visible.includes('unscheduled'),
              }"
              class="toggleable"
              @click="toggle('unscheduled')"
            >
              <span class="title">
                {{ t("labels.roadmap.unscheduled") }}
              </span>
              <small class="text-muted">
                {{
                  t("labels.roadmap.ships", {
                    count: String(unscheduledModels.length),
                  })
                }}
              </small>
              <i class="fa fa-chevron-right" />
            </h2>

            <div
              id="unscheduled-cards"
              v-show-slide:400:ease-in-out="visible.includes('unscheduled')"
            >
              <div class="row">
                <div
                  v-for="model in unscheduledModels"
                  :key="model.slug"
                  class="col-12 col-lg-6 col-xl-4 col-xxl-2dot4 fade-list-item"
                >
                  <RoadmapItem
                    :item="model"
                    :compact="compact"
                    :active="true"
                    :show-progress="false"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import Btn from "@/frontend/core/components/Btn/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import RoadmapItem from "@/frontend/components/Roadmap/RoadmapItem/index.vue";
import EmptyBox from "@/frontend/core/components/EmptyBox/index.vue";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import { useCable } from "@/shared/composables/useCable";
import type { Subscription } from "@rails/actioncable";
import { useI18n } from "@/frontend/composables/useI18n";
import modelsCollection from "@/frontend/api/collections/Models";
import roadmapItemsCollection from "@/frontend/api/collections/RoadmapItems";

const { t } = useI18n();
const loading = ref(true);

const onlyReleased = ref(true);

const compact = ref(true);

const roadmapItems = ref<RoadmapItem[]>([]);

const visible = ref<string[]>([]);

const unscheduledModels = ref<Model[]>([]);

const roadmapChannel = ref<Subscription | null>(null);

const toggleCompactTooltip = computed(() => {
  if (compact.value) {
    return t("actions.showDetails");
  }

  return t("actions.hideDetails");
});

const emptyBoxVisible = computed(
  () => !loading.value && roadmapItems.value.length === 0,
);

const filteredItems = computed<RoadmapItem[]>(() => {
  const items = roadmapItems.value.filter((item) => item.model);

  if (onlyReleased.value) {
    return items.filter((item) => !item.released);
  }

  return items;
});

const groupedByRelease = computed<RoadmapItemsByRelease>(() =>
  filteredItems.value.reduce((rv, x) => {
    const value: RoadmapItemsByRelease = { ...rv };

    value[x.release] = (rv as RoadmapItemsByRelease)[x.release] || [];
    value[x.release].push(x);

    return value;
  }, {}),
);

const crumbs = computed(() => [
  {
    to: {
      name: "roadmap",
    },
    label: t("nav.roadmap.index"),
  },
]);

onMounted(() => {
  fetch();
  setupUpdates();
});

onUnmounted(() => {
  if (roadmapChannel.value) {
    roadmapChannel.value.unsubscribe();
  }
});

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

const toggleCompact = () => {
  compact.value = !compact.value;
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
  Object.keys(groupedByRelease.value).forEach((release) => {
    const items = groupedByRelease.value[release];
    if (items.length && !items[0].released) {
      visible.value.push(release);
    }
  });
};

const fetch = async () => {
  loading.value = true;

  roadmapItems.value = await roadmapItemsCollection.ships();

  loading.value = false;

  await fetchModels();

  openReleased();
};

const fetchModels = async () => {
  unscheduledModels.value = await modelsCollection.unscheduled();
};
</script>

<script lang="ts">
export default {
  name: "RoadmapShipsPage",
};
</script>

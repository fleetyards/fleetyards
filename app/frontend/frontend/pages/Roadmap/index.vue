<template>
  <router-view v-if="isSubRoute" />
  <section v-else class="container roadmap">
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
              @click.native="togglerShowRemoved"
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
                {{
                  t("labels.roadmap.stories", { count: String(items.length) })
                }}
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
                  <RoadmapItem :item="item" />
                </div>
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

<script lang="ts" setup>
import { useRoute } from "vue-router/composables";
import Btn from "@/frontend/core/components/Btn/index.vue";
import Loader from "@/frontend/core/components/Loader/index.vue";
import RoadmapItem from "@/frontend/components/Roadmap/RoadmapItem/index.vue";
import EmptyBox from "@/frontend/core/components/EmptyBox/index.vue";
import BtnDropdown from "@/frontend/core/components/BtnDropdown/index.vue";
import { Subscription } from "@rails/actioncable";
import { useI18n } from "@/frontend/composables/useI18n";
import { useCable } from "@/frontend/composables/useCable";
import roadmapItemsCollection from "@/frontend/api/collections/RoadmapItems";

const { t } = useI18n();
const loading = ref(true);

const onlyReleased = ref(true);

const showRemoved = ref(false);

const roadmapItems = ref<RoadmapItem[]>([]);

const visible = ref<string[]>([]);

const roadmapChannel = ref<Subscription | null>(null);

const releasedToggleLabel = computed(() => {
  if (onlyReleased.value) {
    return t("actions.showReleased");
  }

  return t("actions.hideReleased");
});

const toggleRemovedTooltip = computed(() => {
  if (showRemoved.value) {
    return t("actions.roadmap.hideRemoved");
  }

  return t("actions.roadmap.showRemoved");
});

const route = useRoute();

const isSubRoute = computed(() => route.name !== "roadmap");

const emptyBoxVisible = computed(
  () => !loading.value && roadmapItems.value.length === 0,
);

const filteredItems = computed(() => {
  if (onlyReleased.value) {
    return roadmapItems.value.filter((item) => !item.released);
  }

  return roadmapItems.value;
});

const groupedByRelease = computed<RoadmapItemsByRelease>(() =>
  filteredItems.value.reduce((rv, x) => {
    const value = JSON.parse(JSON.stringify(rv));

    value[x.release] = (rv as RoadmapItemsByRelease)[x.release] || [];
    value[x.release].push(x);

    return value;
  }, {}),
);

onMounted(() => {
  fetch();
  setupUpdates();
});

onUnmounted(() => {
  if (roadmapChannel.value) {
    roadmapChannel.value.unsubscribe();
  }
});

watch(
  () => onlyReleased.value,
  () => {
    fetch();
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
  onlyReleased.value = !onlyReleased.value;
};

const togglerShowRemoved = () => {
  showRemoved.value = !showRemoved.value;

  fetch();
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

  roadmapItems.value = await roadmapItemsCollection.overview();

  loading.value = false;

  openReleased();
};
</script>

<script lang="ts">
export default {
  name: "RoadmapPage",
};
</script>

<template>
  <FilteredList :name="name" :records="records" :async-status="asyncStatus">
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
                <RoadmapItemComp :item="item" />
              </div>
            </div>
          </Collapsed>
        </div>
      </transition-group>
    </template>
  </FilteredList>
</template>

<script lang="ts" setup>
import { type RoadmapItem } from "@/services/fyApi";
import { type AsyncStatus } from "@/shared/components/AsyncData.types";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import RoadmapItemComp from "@/frontend/components/Roadmap/RoadmapItem/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  name: string;
  records: RoadmapItem[];
  asyncStatus: AsyncStatus;
  compact?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  compact: false,
});

const { t } = useI18n();

const visible = ref<string[]>([]);

const toggle = (release: string) => {
  if (visible.value.includes(release)) {
    const index = visible.value.indexOf(release);

    visible.value.splice(index, 1);

    return null;
  }

  return visible.value.push(release);
};

const groupedByRelease = computed(() =>
  props.records.reduce(
    (rv, x) => {
      const value = JSON.parse(JSON.stringify(rv));

      value[x.release] = rv[x.release] || [];
      value[x.release].push(x);

      return value;
    },
    {} as Record<string, RoadmapItem[]>,
  ),
);

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

onMounted(() => {
  openReleased();
});

watch(
  () => props.records,
  () => {
    openReleased();
  },
);

defineExpose({
  openReleased,
});
</script>

<script lang="ts">
export default {
  name: "RoadmapList",
};
</script>

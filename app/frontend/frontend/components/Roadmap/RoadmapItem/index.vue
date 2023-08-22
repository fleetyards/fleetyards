<template>
  <Panel
    v-tooltip="inactiveTooltip"
    class="roadmap-item"
    :class="cssClasses"
    @click.native="openModal"
  >
    <div v-lazy:background-image="storeImage" class="item-image lazy">
      <div
        v-if="recentlyUpdated"
        v-tooltip="t('labels.roadmap.recentlyUpdated')"
        class="roadmap-item-updated"
      />
    </div>
    <div class="item-body">
      <h3>
        <span v-tooltip="item.name">
          {{ item.name }}
        </span>
        <small>
          <div v-tooltip="t('labels.roadmap.lastUpdate')" class="text-muted">
            <span>{{ lastVersionChangedAtLabel }}</span>
            <i v-tooltip="lastVersionChangedAtLabel" class="far fa-clock" />
          </div>
          <div
            v-if="committed"
            v-tooltip="t('labels.roadmap.committed')"
            class="roadmap-item-committed"
          >
            <span class="text-muted">{{ t("labels.roadmap.committed") }}</span>
            <i class="far fa-check" />
          </div>
        </small>
      </h3>
      <p v-if="!compact">{{ description }}</p>
      <ul v-if="lastVersion && !compact">
        <li v-for="(update, index) in updates" :key="index">
          <template v-if="update.key === 'release' && !update.old">
            {{
              t("labels.roadmap.lastVersion.addedToRelease", {
                release: String(update.new),
              })
            }}
          </template>
          <template v-else-if="update.key === 'released'">
            {{ t(`labels.roadmap.lastVersion.released`) }}
          </template>
          <template v-else-if="update.key === 'commited'">
            {{ t(`labels.roadmap.lastVersion.committed`) }}
          </template>
          <template v-else-if="update.key === 'active'">
            {{ t(`labels.roadmap.lastVersion.active.${update.change}`) }}
          </template>
          <template v-else>
            {{
              t(`labels.roadmap.lastVersion.${update.key}`, {
                old: String(update.old),
                new: String(update.new),
                count: String(update.count),
              })
            }}
          </template>
        </li>
      </ul>
    </div>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import { isBefore, addHours } from "date-fns";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/frontend/composables/useI18n";

const { t } = useI18n();

type Props = {
  item: RoadmapItem | Model;
  compact?: boolean;
  showProgress?: boolean;
  active?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  compact: true,
  showProgress: true,
  active: false,
});

const storeImage = computed(() => {
  if (props.item.media.storeImage?.small) {
    return props.item.media.storeImage.small;
  }

  if ((props.item as RoadmapItem).image) {
    return `https://robertsspaceindustries.com${
      (props.item as RoadmapItem).image
    }`;
  }

  return null;
});

const lastVersionChangedAtLabel = computed(() => {
  if ((props.item as RoadmapItem).lastVersionChangedAtLabel) {
    return (props.item as RoadmapItem).lastVersionChangedAtLabel;
  }

  return null;
});

const committed = computed(() => {
  if ((props.item as RoadmapItem).committed) {
    return (props.item as RoadmapItem).committed;
  }

  return null;
});

const lastVersion = computed(() => {
  if ((props.item as RoadmapItem).lastVersion) {
    return (props.item as RoadmapItem).lastVersion;
  }

  return null;
});

const description = computed(() => {
  if ((props.item as RoadmapItem).body) {
    return (props.item as RoadmapItem).body;
  }

  return props.item.description;
});

const recentlyUpdated = computed(() =>
  isBefore(
    new Date(),
    addHours(new Date((props.item as RoadmapItem).lastVersionChangedAt), 24),
  ),
);

const cssClasses = computed(() => ({
  compact: props.compact,
  inactive: !(props.item as RoadmapItem).active && !props.active,
}));

const inactiveTooltip = computed(() => {
  if (!(props.item as RoadmapItem).active) {
    return t("texts.roadmap.inactive");
  }
  return null;
});

const updates = computed(() => {
  if (!props.item) {
    return [];
  }

  const { lastVersion } = props.item as RoadmapItem;

  if (!lastVersion) {
    return [];
  }

  return ["committed", "release", "released", "active"]
    .filter((key) => lastVersion[key as keyof RoadmapVersionItem])
    .map((key) => {
      let count = null;
      if (key === "committed") {
        const oldValue = lastVersion.committed[0];
        const newValue = lastVersion.committed[1];
        count = Number(newValue) - Number(oldValue);
      }

      let change = null;
      if (count) {
        change = count < 0 ? "decreased" : "increased";
      }

      return {
        key,
        change,
        old: lastVersion[key as keyof RoadmapVersionItem][0],
        new: lastVersion[key as keyof RoadmapVersionItem][1],
        count,
      };
    })
    .filter(
      (update) =>
        update.key !== "released" || (update.key === "released" && update.old),
    )
    .filter(
      (update) =>
        update.key !== "commited" || (update.key === "commited" && update.old),
    )
    .filter(
      (update) =>
        update.key !== "active" || (update.key === "active" && update.old),
    );
});

const comlink = useComlink();

const openModal = () => {
  comlink.$emit("open-modal", {
    component: () =>
      import("@/frontend/components/Roadmap/RoadmapItem/Modal/index.vue"),
    props: {
      item: props.item,
    },
  });
};
</script>

<script lang="ts">
export default {
  name: "RoadmapItem",
};
</script>

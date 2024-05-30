<script lang="ts">
export default {
  name: "RoadmapItem",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import PanelImage from "@/shared/components/Panel/Image/index.vue";
import PanelBody from "@/shared/components/Panel/Body/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { type RoadmapItem } from "@/services/fyApi";
import RoadmapItemUpdates from "@/frontend/components/Roadmap/RoadmapItem/Updates/index.vue";
import RoadmapItemStatus from "@/frontend/components/Roadmap/RoadmapItem/Status/index.vue";

const { t } = useI18n();

type Props = {
  item: RoadmapItem;
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

const description = computed(() => {
  if ((props.item as RoadmapItem).body) {
    return (props.item as RoadmapItem).body;
  }

  return props.item.description;
});

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

const comlink = useComlink();

const openModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Roadmap/RoadmapItem/Modal/index.vue"),
    props: {
      item: props.item,
    },
  });
};
</script>

<template>
  <Panel
    v-tooltip="inactiveTooltip"
    class="roadmap-item"
    :class="cssClasses"
    alignment="left"
    slim
    @click="openModal"
  >
    <PanelImage
      v-if="storeImage"
      :image="storeImage"
      image-size="auto"
      rounded="left"
      :alt="item.name"
    />
    <div>
      <PanelHeading level="h3" :multiline="!compact">
        <span v-tooltip="item.name">
          {{ item.name }}
        </span>
        <RoadmapItemStatus :item="item" :compact="compact" />
      </PanelHeading>
      <PanelBody v-if="!compact" no-min-height no-padding-top>
        <p>{{ description }}</p>
        <RoadmapItemUpdates :item="item" />
      </PanelBody>
    </div>
  </Panel>
</template>

<style lang="scss" scoped>
@import "index";
</style>

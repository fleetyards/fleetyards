<script lang="ts">
export default {
  name: "RoadmapItemStatus",
};
</script>

<script lang="ts" setup>
import { type RoadmapItem } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  item: RoadmapItem;
  compact: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  compact: true,
});

const { t } = useI18n();

const lastVersionChangedAtLabel = computed(() => {
  if (props.item.lastVersionChangedAtLabel) {
    return props.item.lastVersionChangedAtLabel;
  }

  return undefined;
});

const committed = computed(() => {
  if (props.item.committed) {
    return props.item.committed;
  }

  return undefined;
});
</script>

<template>
  <small
    class="roadmap-item-status"
    :class="{
      'roadmap-item-status-compact': compact,
    }"
  >
    <div v-tooltip="t('labels.roadmap.lastUpdate')" class="text-muted">
      <span v-if="!compact">{{ lastVersionChangedAtLabel }}</span>
      <i v-tooltip="lastVersionChangedAtLabel" class="far fa-clock" />
    </div>
    <div
      v-if="committed"
      v-tooltip="t('labels.roadmap.committed')"
      class="roadmap-item-status-committed"
    >
      <span v-if="!compact" class="text-muted">{{
        t("labels.roadmap.committed")
      }}</span>
      <i class="far fa-check" />
    </div>
  </small>
</template>

<style lang="scss" scoped>
@import "index";
</style>

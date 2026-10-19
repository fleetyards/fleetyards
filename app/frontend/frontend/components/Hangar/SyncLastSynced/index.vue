<script lang="ts">
export default {
  name: "HangarSyncLastSynced",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  // When the last sync finished; nothing is shown without one.
  finishedAt?: string | null;
};

const props = withDefaults(defineProps<Props>(), {
  finishedAt: undefined,
});

const { t, l, timeDistance } = useI18n();
</script>

<template>
  <p
    v-if="props.finishedAt"
    class="sync-last-synced"
    data-test="sync-last-synced"
  >
    <i class="fa-light fa-clock-rotate-left" aria-hidden="true" />
    <span>
      {{ t("labels.syncExtension.lastSynced") }}
      <time v-tooltip="l(props.finishedAt)" :datetime="props.finishedAt">
        {{ timeDistance(props.finishedAt) }}
      </time>
    </span>
  </p>
</template>

<style lang="scss" scoped>
.sync-last-synced {
  display: flex;
  align-items: baseline;
  gap: 10px;
  margin: 0;
  color: var(--color-text-dim, #959595);
  font-size: 14px;

  i {
    width: 16px;
    color: var(--color-muted, #7a8288);
    text-align: center;
  }
}
</style>

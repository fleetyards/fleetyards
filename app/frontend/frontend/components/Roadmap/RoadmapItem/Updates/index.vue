<script lang="ts">
export default {
  name: "RoadmapItemUpdates",
};
</script>

<script lang="ts" setup>
import { type RoadmapItem } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  item: RoadmapItem;
};

const props = defineProps<Props>();

const { t } = useI18n();

const changesetKeys = [
  "committed",
  "release",
  "released",
  "active",
] as (keyof typeof lastVersion.value)[];

const lastVersion = computed(() => {
  return props.item.lastVersion;
});

const updates = computed(() => {
  if (!lastVersion.value) {
    return [];
  }

  return changesetKeys
    .filter((key) => {
      if (!lastVersion.value) {
        return false;
      }

      return lastVersion.value[key];
    })
    .map((key) => {
      if (!lastVersion.value || ["released", "committed"].includes(key)) {
        return {
          key,
          old: undefined,
          new: undefined,
        };
      }

      if (key === "active") {
        return {
          key,
          old: (lastVersion.value.active || [])[0],
          new: (lastVersion.value.active || [])[1],
        };
      }

      // key === "release"
      return {
        key,
        old: (lastVersion.value.release || [])[0] || "",
        new: (lastVersion.value.release || [])[1] || "",
      };
    });
});
</script>

<template>
  <ul v-if="lastVersion">
    <li v-for="(update, index) in updates" :key="index">
      <template v-if="update.key === 'release' && !update.old">
        {{
          t("labels.roadmap.lastVersion.addedToRelease", {
            release: update.new as string,
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
        {{ t(`labels.roadmap.lastVersion.active.${update.new}`) }}
      </template>
      <template v-else>
        {{
          t(`labels.roadmap.lastVersion.${update.key}`, {
            old: update.old as string,
            new: update.new as string,
          })
        }}
      </template>
    </li>
  </ul>
</template>

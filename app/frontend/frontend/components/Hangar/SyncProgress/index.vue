<script lang="ts">
export default {
  name: "HangarSyncProgress",
};
</script>

<script lang="ts" setup>
import SyncProgressCard from "@/frontend/components/Hangar/SyncProgressCard/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useHangarSync } from "@/frontend/composables/useHangarSync";
import { useHangarStore } from "@/frontend/stores/hangar";

const { t } = useI18n();

const { running, fetching, currentPage, cancel } = useHangarSync();

const hangarStore = useHangarStore();

const comlink = useComlink();

const open = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/SyncBtn/Modal/index.vue"),
  });
};
</script>

<template>
  <transition name="fade">
    <SyncProgressCard
      v-if="running && !hangarStore.syncModalOpen"
      data-test="hangar-sync-progress"
    >
      <span>{{ t("labels.syncExtension.backgroundProgress") }}</span>
      <span
        v-if="fetching"
        class="hangar-sync-progress__count"
        data-test="hangar-sync-page"
      >
        {{ t("labels.syncExtension.pledgeItems.pages") }}:
        {{ currentPage }}
      </span>
      <Btn
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.GHOST"
        data-test="open-hangar-sync"
        @click="open"
      >
        {{ t("actions.showDetails") }}
      </Btn>
      <Btn
        v-if="fetching"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.GHOST"
        data-test="cancel-hangar-sync"
        @click="cancel"
      >
        {{ t("actions.syncExtension.cancel") }}
      </Btn>
    </SyncProgressCard>
  </transition>
</template>

<style lang="scss" scoped>
.hangar-sync-progress__count {
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}
</style>

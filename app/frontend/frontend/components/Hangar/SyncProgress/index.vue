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

const {
  started,
  running,
  fetching,
  finishedWithErrors,
  retryable,
  cancelled,
  currentPage,
  cancel,
  reset,
} = useHangarSync();

// A run that ended in the background stays up until its result is opened or
// dismissed, so the outcome is not only a toast that was easy to miss.
const ended = computed(() => started.value && !running.value);

const failed = computed(
  () => !cancelled.value && (finishedWithErrors.value || retryable.value),
);

const endedLabel = computed(() => {
  if (cancelled.value) return t("labels.syncExtension.backgroundCancelled");

  return failed.value
    ? t("labels.syncExtension.backgroundFailed")
    : t("labels.syncExtension.backgroundFinished");
});

const endedClass = computed(() => {
  if (cancelled.value) return undefined;

  return failed.value ? "text-danger" : "text-success";
});

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
      v-if="(running || ended) && !hangarStore.syncModalOpen"
      :loading="running"
      data-test="hangar-sync-progress"
    >
      <span v-if="running">{{
        t("labels.syncExtension.backgroundProgress")
      }}</span>
      <span v-else :class="endedClass" data-test="hangar-sync-ended">
        {{ endedLabel }}
      </span>
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
        {{
          ended
            ? t("actions.syncExtension.showResult")
            : t("actions.showDetails")
        }}
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
      <Btn
        v-if="ended"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.GHOST"
        data-test="dismiss-hangar-sync"
        @click="reset()"
      >
        {{ t("actions.syncExtension.close") }}
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

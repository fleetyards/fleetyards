<script lang="ts">
export default {
  name: "HangarBuybackSyncProgress",
};
</script>

<script lang="ts" setup>
import FloatingProgress from "@/frontend/components/Hangar/FloatingProgress/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useBuybackDetailsSync } from "@/frontend/composables/useBuybackDetailsSync";
import { useBuybackSync } from "@/frontend/composables/useBuybackSync";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useSessionStore } from "@/frontend/stores/session";

const { t } = useI18n();

const { displaySuccess, displayWarning } = useAppNotifications();

const details = useBuybackDetailsSync();

const list = useBuybackSync();

const hangarStore = useHangarStore();

const sessionStore = useSessionStore();

const comlink = useComlink();

// The list is read and saved first, then the prices; a cancelled price pass
// sends nothing more and only waits on its last answer.
const stage = computed(() => {
  if (list.status.value === "fetching") return "fetching";
  if (list.status.value === "submitting") return "submitting";
  if (details.running.value && !details.cancelling.value) return "details";
  return undefined;
});

// The modal that started the pass is usually long closed by the time it ends,
// so how it ended is told here.
watch(details.status, (current, previous) => {
  if (previous !== "running") return;

  if (current === "finished") {
    displaySuccess({ text: t("messages.buybackSync.detailsSuccess") });
  } else if (current === "incomplete") {
    displayWarning({ text: t("texts.buybackSync.detailsIncomplete") });
  }
});

// Anything stored after a sign-out would land on an account that is no longer
// here, or on the next one to sign in.
watch(
  () => sessionStore.isAuthenticated,
  (authenticated) => {
    if (authenticated) return;

    list.reset(true);
    details.discard();
  },
);

const open = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/BuybackSyncBtn/Modal/index.vue"),
  });
};

const cancel = () => {
  if (stage.value === "details") {
    details.cancel();
  } else {
    list.cancel();
  }
};
</script>

<template>
  <transition name="fade">
    <FloatingProgress
      v-if="stage && !hangarStore.buybackSyncModalOpen"
      data-test="buyback-sync-progress-card"
    >
      <span data-test="buyback-sync-stage">
        {{
          stage === "details"
            ? t("labels.buybackSync.detailsProgress")
            : t(`labels.buybackSync.status.${stage}`)
        }}
      </span>
      <span
        v-if="stage !== 'submitting'"
        class="buyback-sync-progress__count"
        data-test="buyback-sync-count"
      >
        <template v-if="stage === 'details'">
          {{ details.done.value }} / {{ details.total.value }}
        </template>
        <template v-else>
          {{ t("labels.buybackSync.pages") }}: {{ list.currentPage.value }}
        </template>
      </span>
      <Btn
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.GHOST"
        data-test="open-buyback-sync-progress"
        @click="open"
      >
        {{ t("actions.showDetails") }}
      </Btn>
      <Btn
        v-if="stage !== 'submitting'"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.GHOST"
        data-test="cancel-buyback-sync-progress"
        @click="cancel"
      >
        {{ t("actions.syncExtension.cancel") }}
      </Btn>
    </FloatingProgress>
  </transition>
</template>

<style lang="scss" scoped>
.buyback-sync-progress__count {
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}
</style>

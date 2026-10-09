<script lang="ts">
export default {
  name: "HangarBuybackDetailsSyncProgress",
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
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useBuybackDetailsSync } from "@/frontend/composables/useBuybackDetailsSync";
import { useSessionStore } from "@/frontend/stores/session";

const { t } = useI18n();

const { displaySuccess, displayWarning } = useAppNotifications();

const { status, total, done, running, cancelling, cancel, discard } =
  useBuybackDetailsSync();

const sessionStore = useSessionStore();

// The modal that started the pass is usually long closed by the time it ends,
// so how it ended is told here.
watch(status, (current, previous) => {
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
    if (!authenticated) discard();
  },
);
</script>

<template>
  <transition name="fade">
    <FloatingProgress
      v-if="running && !cancelling"
      data-test="buyback-details-sync-progress"
    >
      <span>{{ t("labels.buybackSync.detailsProgress") }}</span>
      <span
        class="buyback-details-sync-progress__count"
        data-test="buyback-details-sync-count"
      >
        {{ done }} / {{ total }}
      </span>
      <Btn
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.GHOST"
        data-test="cancel-buyback-details-sync"
        @click="cancel"
      >
        {{ t("actions.syncExtension.cancel") }}
      </Btn>
    </FloatingProgress>
  </transition>
</template>

<style lang="scss" scoped>
.buyback-details-sync-progress__count {
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}
</style>

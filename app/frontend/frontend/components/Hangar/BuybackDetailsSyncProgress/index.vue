<script lang="ts">
export default {
  name: "HangarBuybackDetailsSyncProgress",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
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

const { status, total, done, running, cancel } = useBuybackDetailsSync();

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

// What it reads after a sign-out would be stored for an account that is no
// longer here.
watch(
  () => sessionStore.isAuthenticated,
  (authenticated) => {
    if (!authenticated) cancel();
  },
);
</script>

<template>
  <transition name="fade">
    <div
      v-if="running"
      class="buyback-details-sync-progress"
      data-test="buyback-details-sync-progress"
    >
      <Panel :loading="true" :outer-spacing="false">
        <div class="buyback-details-sync-progress__body">
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
        </div>
      </Panel>
    </div>
  </transition>
</template>

<style lang="scss" scoped>
// Below AppModal (1050), so a modal opened meanwhile covers it.
.buyback-details-sync-progress {
  position: fixed;
  right: calc(20px + env(safe-area-inset-right));
  bottom: calc(20px + env(safe-area-inset-bottom));
  z-index: 1040;
  max-width: calc(100vw - 40px);
}

.buyback-details-sync-progress__body {
  display: flex;
  align-items: center;
  gap: 15px;
  padding: 10px 15px;
}

.buyback-details-sync-progress__count {
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}
</style>

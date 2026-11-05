<script lang="ts">
export default {
  name: "AppLoadFailedHint",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import MessageBody from "@/shared/components/AppNotifications/Message/Body/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const reload = () => {
  window.location.reload();
};
</script>

<template>
  <MessageBody>
    <div class="app-update-hint">
      <div class="app-update-hint__heading">
        <i class="fa-light fa-triangle-exclamation app-update-hint__icon" />
        <strong>{{ t("headlines.appLoadFailed") }}</strong>
      </div>
      <p class="app-update-hint__body">
        {{ t("texts.appLoadFailed") }}
      </p>
      <div class="app-update-hint__actions" @click.stop>
        <Btn data-test="app-load-failed-reload" @click="reload">
          {{ t("actions.appUpdate.reload") }}
        </Btn>
      </div>
    </div>
  </MessageBody>
</template>

<style lang="scss" scoped>
@import "../AppUpdateHint/index";
</style>

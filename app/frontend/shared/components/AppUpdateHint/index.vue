<script lang="ts">
export default {
  name: "AppUpdateHint",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import MessageBody from "@/shared/components/AppNotifications/Message/Body/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  version: string;
  codename?: string;
  whatsNewUrl: string;
};

const props = withDefaults(defineProps<Props>(), {
  codename: undefined,
});

const { t } = useI18n();

// Leaving the tab for the notes would leave it on the old version, so a link
// back into this app reloads it in place and only an outside page opens anew.
const whatsNewTarget = computed(() =>
  new URL(props.whatsNewUrl, window.location.href).origin ===
  window.location.origin
    ? "_self"
    : "_blank",
);

const reload = () => {
  window.location.reload();
};
</script>

<template>
  <MessageBody>
    <div class="app-update-hint">
      <div class="app-update-hint__heading">
        <i class="fa-light fa-sparkles app-update-hint__icon" />
        <strong>{{ t("headlines.appUpdate") }}</strong>
      </div>
      <p class="app-update-hint__body">
        {{
          codename
            ? t("texts.appUpdate.withCodename", { version, codename })
            : t("texts.appUpdate.plain", { version })
        }}
      </p>
      <div class="app-update-hint__actions" @click.stop>
        <Btn data-test="app-update-reload" @click="reload">
          {{ t("actions.appUpdate.reload") }}
        </Btn>
        <Btn
          data-test="app-update-whats-new"
          :href="whatsNewUrl"
          :target="whatsNewTarget"
          :variant="BtnVariantsEnum.BARE"
        >
          {{ t("actions.appUpdate.whatsNew") }}
        </Btn>
      </div>
    </div>
  </MessageBody>
</template>

<style lang="scss" scoped>
@import "./index";
</style>

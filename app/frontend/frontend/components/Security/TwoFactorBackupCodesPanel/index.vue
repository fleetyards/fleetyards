<template>
  <Panel class="codes-panel" inset>
    <p>
      {{ t("texts.twoFactor.backupCodes") }}
    </p>
    <div class="row d-flex justify-content-center codes-panel-inner">
      <div
        v-for="backupCode in codes"
        :key="backupCode"
        class="col-6 text-center"
      >
        {{ backupCode }}
      </div>
    </div>
    <hr />
    <div class="d-flex justify-content-center">
      <Btn :variant="BtnVariantsEnum.LINK" @click="copyCodes">
        {{ t("actions.copyBackupCodes") }}
      </Btn>
    </div>
  </Panel>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import copyText from "@/frontend/utils/CopyText";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import Panel from "@/shared/components/Panel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";

type Props = {
  codes: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const copyCodes = () => {
  copyText(props.codes.join("\n")).then(
    () => {
      displaySuccess({
        text: t("messages.copyBackupCodes.success"),
      });
    },
    () => {
      displayAlert({
        text: t("messages.copyBackupCodes.failure"),
      });
    },
  );
};
</script>

<script lang="ts">
export default {
  name: "TwoFactorBackupCodesPanel",
};
</script>

<style lang="scss" scoped>
.codes-panel {
  margin: 40px 0;

  .codes-panel-inner {
    margin: 20px 0;
  }
}
</style>

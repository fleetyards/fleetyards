<template>
  <Panel class="codes-panel" inset>
    <p>
      {{ $t("texts.twoFactor.backupCodes") }}
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
      <Btn variant="link" @click.native="copyCodes">
        {{ $t("actions.copyBackupCodes") }}
      </Btn>
    </div>
  </Panel>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop } from "vue-property-decorator";
import Btn from "@/shared/components/base/Btn/index.vue";
import copyText from "@/frontend/utils/CopyText";
import { displaySuccess, displayAlert } from "@/frontend/lib/Noty";
import Panel from "@/shared/components/Panel/index.vue";

@Component<TwoFactorBackupCodesPanel>({
  components: {
    Panel,
    Btn,
  },
})
export default class TwoFactorBackupCodesPanel extends Vue {
  @Prop({ required: true }) codes: string[];

  copyCodes() {
    copyText(this.codes.join("\n")).then(
      () => {
        displaySuccess({
          text: this.$t("messages.copyBackupCodes.success"),
        });
      },
      () => {
        displayAlert({
          text: this.$t("messages.copyBackupCodes.failure"),
        });
      },
    );
  }
}
</script>

<style lang="scss" scoped>
.codes-panel {
  margin: 40px 0;

  .codes-panel-inner {
    margin: 20px 0;
  }
}
</style>

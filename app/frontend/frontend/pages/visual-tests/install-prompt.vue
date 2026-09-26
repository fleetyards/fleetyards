<script lang="ts">
export default {
  name: "VisualTestsInstallPromptPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useInstallPrompt } from "@/frontend/composables/useInstallPrompt";

const { canInstall, isIos, isStandalone, forceOffer, openIosInstructions } =
  useInstallPrompt();
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">State</Heading>
  <ul data-test="install-prompt-state">
    <li>canInstall: {{ canInstall }}</li>
    <li>isIos: {{ isIos }}</li>
    <li>isStandalone: {{ isStandalone }}</li>
  </ul>

  <Heading :level="HeadingLevelEnum.H2">Trigger</Heading>
  <p>Bypasses the first-visit check and the cooldown.</p>
  <div class="row">
    <div class="col-12 vt-row">
      <Btn data-test="trigger-install-hint" @click="forceOffer('eventSignup')">
        Offer after event signup
      </Btn>
      <Btn data-test="open-ios-instructions" @click="openIosInstructions">
        iOS instructions
      </Btn>
    </div>
  </div>
</template>

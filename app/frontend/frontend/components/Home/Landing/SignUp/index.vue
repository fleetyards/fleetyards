<script lang="ts">
export default {
  name: "HomeLandingSignUp",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelTonesEnum } from "@/shared/components/base/Panel/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<template>
  <Panel
    :tone="PanelTonesEnum.PRIMARY"
    class="home-landing-sign-up-panel"
    data-test="home-landing-sign-up"
  >
    <PanelHeading :level="HeadingLevelEnum.H2">
      {{ t("home.landing.signUpPanel.title") }}
    </PanelHeading>
    <PanelBody class="home-landing-sign-up">
      <p>{{ t("home.landing.signUpPanel.text") }}</p>
      <div>
        <Btn :size="BtnSizesEnum.LG" :to="{ name: 'signup' }">
          <i class="fa-light fa-user-plus" />
          {{ t("home.landing.signUp") }}
        </Btn>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.home-landing-sign-up-panel {
  max-width: 560px;
  margin-right: auto;
  margin-left: auto;
  text-align: center;

  :deep(.panel-heading) {
    justify-content: center;
  }

  :deep(.panel-heading__title) {
    align-items: center;
  }
}

.home-landing-sign-up {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 14px;

  p {
    margin: 0;
  }
}
</style>

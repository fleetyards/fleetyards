<script lang="ts">
export default {
  name: "HangarPreviewPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import { PanelTransparenciesEnum } from "@/shared/components/Panel/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useHangarStore } from "@/frontend/stores/hangar";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";

const { t } = useI18n();

const hangarStore = useHangarStore();

const redirectBackStore = useRedirectBackStore();

const setBackRoute = () => {
  redirectBackStore.backRoute = {
    name: "hangar",
  };
};

const handleLogin = () => {
  hangarStore.hidePreview();

  setBackRoute();
};
</script>

<template>
  <div class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12">
          <h1 class="sr-only">
            {{ t("headlines.hangar.preview.h1") }}
          </h1>
        </div>
      </div>

      <div class="row">
        <div class="col-12">
          <h2 class="text-center main-headline">
            {{ t("headlines.hangar.preview.h2") }}
          </h2>
        </div>
      </div>

      <hr class="large-spacer" />

      <div class="row">
        <div class="col-12">
          <h3 class="text-center main-subheadline">
            {{ t("headlines.hangar.preview.h3") }}
          </h3>
        </div>
      </div>

      <br />

      <div class="row">
        <div class="col-12 col-lg-4">
          <Panel
            class="info-box"
            :transparency="PanelTransparenciesEnum.MORE"
            inset
          >
            <div class="panel-heading">
              <h2 class="panel-title text-center">
                {{ t("texts.hangarPreview.notified.headline") }}
              </h2>
            </div>
            <div class="panel-body text-center">
              <!-- eslint-disable-next-line vue/no-v-html -->
              <p v-html="t('texts.hangarPreview.notified.text')" />
            </div>
          </Panel>
        </div>
        <div class="col-12 col-lg-4">
          <Panel
            class="info-box"
            :transparency="PanelTransparenciesEnum.MORE"
            inset
          >
            <div class="panel-heading">
              <h2 class="panel-title text-center">
                {{ t("texts.hangarPreview.manage.headline") }}
              </h2>
            </div>
            <div class="panel-body text-center">
              <!-- eslint-disable-next-line vue/no-v-html -->
              <p v-html="t('texts.hangarPreview.manage.text')" />
            </div>
          </Panel>
        </div>
        <div class="col-12 col-lg-4">
          <Panel
            class="info-box"
            :transparency="PanelTransparenciesEnum.MORE"
            inset
          >
            <div class="panel-heading">
              <h2 class="panel-title text-center">
                {{ t("texts.hangarPreview.fleetchart.headline") }}
              </h2>
            </div>
            <div class="panel-body text-center">
              <!-- eslint-disable-next-line vue/no-v-html -->
              <p v-html="t('texts.hangarPreview.fleetchart.text')" />
            </div>
          </Panel>
        </div>
      </div>

      <hr class="large-spacer" />

      <div class="row justify-content-center">
        <div class="col-12 col-lg-4">
          <Btn
            :to="{
              name: 'signup',
            }"
            data-test="signup"
            :size="BtnSizesEnum.LARGE"
            :block="true"
            @click="setBackRoute"
          >
            {{ t("actions.signUp") }}
          </Btn>

          <hr />

          <p class="text-center">
            {{ t("labels.alreadyRegistered") }}
          </p>

          <Btn
            data-test="login"
            :block="true"
            :to="{
              name: 'login',
            }"
            @click="handleLogin"
          >
            {{ t("actions.login") }}
          </Btn>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "preview";
</style>

<script lang="ts">
export default {
  name: "InstallAppIosModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const steps = [
  { icon: "fa-light fa-arrow-up-from-square", key: "iosShare" },
  { icon: "fa-light fa-square-plus", key: "iosAdd" },
  { icon: "fa-light fa-check", key: "iosConfirm" },
];
</script>

<template>
  <Modal :title="t('headlines.installApp.ios')">
    <p>{{ t("texts.installApp.iosIntro") }}</p>
    <ol class="install-app-ios" data-test="install-app-ios-steps">
      <li v-for="step in steps" :key="step.key" class="install-app-ios__step">
        <i :class="step.icon" class="install-app-ios__icon" />
        <span>{{ t(`texts.installApp.${step.key}`) }}</span>
      </li>
    </ol>
  </Modal>
</template>

<style lang="scss" scoped>
.install-app-ios {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;

  &__step {
    display: flex;
    align-items: baseline;
    gap: 0.75rem;
    line-height: 1.4;
  }

  &__icon {
    flex: 0 0 1.25rem;
    text-align: center;
    color: var(--color-primary);
  }
}
</style>

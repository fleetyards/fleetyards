<script lang="ts">
export default {
  name: "FeaturePreview",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { HeadingAlignmentEnum } from "@/shared/components/base/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";
import type { FeaturePreviewItem } from "./types";

type Props = {
  title: string;
  lead: string;
  features: FeaturePreviewItem[];
  // Where the visitor lands once signed up or logged in.
  backRoute: RouteLocationRaw;
};

const props = defineProps<Props>();

const emit = defineEmits<{ login: [] }>();

const { t } = useI18n();

const redirectBackStore = useRedirectBackStore();

const setBackRoute = () => {
  redirectBackStore.setBackRoute(props.backRoute);
};

const handleLogin = () => {
  emit("login");
  setBackRoute();
};
</script>

<template>
  <div class="feature-preview">
    <Heading hero :alignment="HeadingAlignmentEnum.CENTER" mb>
      {{ title }}
      <template #subHeading>{{ lead }}</template>
    </Heading>

    <ul class="feature-preview__grid">
      <li
        v-for="feature in features"
        :key="feature.id"
        class="feature-preview__item"
        :data-test="`feature-${feature.id}`"
      >
        <span class="feature-preview__icon" aria-hidden="true">
          <i :class="feature.icon" />
        </span>
        <h2 class="feature-preview__title">{{ feature.title }}</h2>
        <p class="feature-preview__text">{{ feature.text }}</p>
      </li>
    </ul>

    <div class="feature-preview__cta">
      <Btn
        :to="{ name: 'signup' }"
        data-test="signup"
        :size="BtnSizesEnum.LG"
        :variant="BtnVariantsEnum.SOLID"
        :block="true"
        @click="setBackRoute"
      >
        {{ t("actions.signUp") }}
      </Btn>
      <p class="feature-preview__login">
        {{ t("labels.alreadyRegistered") }}
        <Btn
          :to="{ name: 'login' }"
          data-test="login"
          :size="BtnSizesEnum.SM"
          @click="handleLogin"
        >
          {{ t("actions.login") }}
        </Btn>
      </p>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>

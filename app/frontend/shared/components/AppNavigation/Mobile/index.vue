<script lang="ts">
export default {
  name: "AppNavigationMobile",
};
</script>

<script lang="ts" setup>
import { useNavStore } from "@/shared/stores/nav";
import { storeToRefs } from "pinia";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const navStore = useNavStore();

const { collapsed: navCollapsed } = storeToRefs(navStore);
</script>

<template>
  <div class="navigation-mobile">
    <ul class="navigation-mobile__items">
      <slot />
      <li>
        <button
          :class="{
            'navigation-mobile__toggle--collapsed': navCollapsed,
          }"
          class="navigation-mobile__toggle"
          type="button"
          aria-label="Toggle Navigation"
          @click.stop.prevent="navStore.toggle"
        >
          <span class="sr-only">
            {{ t("labels.toggleNavigation") }}
          </span>
          <span
            class="navigation-mobile__toggle__icon-bar navigation-mobile__toggle__icon-bar--top-bar"
          />
          <span
            class="navigation-mobile__toggle__icon-bar navigation-mobile__toggle__icon-bar--middle-bar"
          />
          <span
            class="navigation-mobile__toggle__icon-bar navigation-mobile__toggle__icon-bar--bottom-bar"
          />
        </button>
      </li>
    </ul>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>

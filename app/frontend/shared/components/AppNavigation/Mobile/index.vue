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
  <div class="navigation-mobile noselect">
    <div class="navigation-items">
      <slot />
      <button
        :class="{
          collapsed: navCollapsed,
        }"
        class="nav-toggle"
        type="button"
        aria-label="Toggle Navigation"
        @click.stop.prevent="navStore.toggle"
      >
        <span class="sr-only">
          {{ t("labels.toggleNavigation") }}
        </span>
        <span class="icon-bar top-bar" />
        <span class="icon-bar middle-bar" />
        <span class="icon-bar bottom-bar" />
      </button>
    </div>
  </div>
</template>

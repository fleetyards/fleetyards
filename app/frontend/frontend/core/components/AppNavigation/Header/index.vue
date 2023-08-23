<template>
  <header class="navigation-header">
    <div
      v-if="nodeEnv && !mobile"
      :class="{
        'spacing-right': $route.name === 'home',
      }"
      class="environment-label"
    >
      <span :class="environmentLabelClasses">
        <i class="far fa-info-circle" />
        {{ nodeEnv }}
      </span>
      <span class="git-revision" :class="environmentLabelClasses">
        <i class="far fa-fingerprint" />
        {{ gitRevision }}
      </span>
    </div>
    <QuickSearch v-if="$route.meta.quickSearch" />
    <Search v-if="$route.meta.search" />
  </header>
</template>

<script lang="ts" setup>
import QuickSearch from "../QuickSearch/index.vue";
import Search from "../Search/index.vue";
import { useAppStore } from "@/frontend/stores/app";
import { storeToRefs } from "pinia";
import { useMobile } from "@/shared/composables/useMobile";

const appStore = useAppStore();

const { gitRevision } = storeToRefs(appStore);

const mobile = useMobile();

const environmentLabelClasses = computed(() => {
  const cssClasses = ["pill"];

  if (window.NODE_ENV === "staging") {
    cssClasses.push("pill-warning");
  } else if (window.NODE_ENV === "production") {
    cssClasses.push("pill-danger");
  }

  return cssClasses;
});

const nodeEnv = computed(() => {
  if (window.NODE_ENV === "production") {
    return null;
  }

  return (window.NODE_ENV || "").toUpperCase();
});
</script>

<script lang="ts">
export default {
  name: "AppNavigationHeader",
};
</script>

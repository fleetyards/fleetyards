<template>
  <div v-if="nodeEnv && !mobile" class="app-environment" :class="cssClasses">
    <span :class="environmentLabelClasses">
      <i class="far fa-info-circle" />
      {{ nodeEnv }}
    </span>
    <span
      class="app-environment--git-revision"
      :class="environmentLabelClasses"
    >
      <i class="far fa-fingerprint" />
      {{ gitRevision }}
    </span>
  </div>
</template>

<script lang="ts" setup>
import { useMobile } from "@/shared/composables/useMobile";

type Props = {
  gitRevision?: string;
};

defineProps<Props>();

const mobile = useMobile();

const route = useRoute();

const cssClasses = computed(() => {
  return {
    "app-environment--with-primary-action": route.meta.primaryAction,
  };
});
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
    return undefined;
  }

  return (window.NODE_ENV || "").toUpperCase();
});
</script>

<script lang="ts">
export default {
  name: "AppEnvironment",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>

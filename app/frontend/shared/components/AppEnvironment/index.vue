<template>
  <div v-if="nodeEnv && !mobile" class="app-environment" :class="cssClasses">
    <BasePill :variant="environtmentVariant">
      <i class="far fa-info-circle" />
      {{ nodeEnv }}
    </BasePill>
    <BasePill
      :variant="environtmentVariant"
      class="app-environment--git-revision"
    >
      <i class="far fa-fingerprint" />
      {{ gitRevision }}
    </BasePill>
  </div>
</template>

<script lang="ts" setup>
import BasePill from "@/shared/components/base/Pill/index.vue";
import { useMobile } from "@/shared/composables/useMobile";

type Props = {
  gitRevision?: string;
};

defineProps<Props>();

const mobile = useMobile();

const route = useRoute();

const environtmentVariant = computed(() => {
  if (window.NODE_ENV === "staging") {
    return "warning";
  } else if (window.NODE_ENV === "production") {
    return "danger";
  }

  return "default";
});

const cssClasses = computed(() => {
  return {
    "app-environment--with-primary-action": route.meta.primaryAction,
  };
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

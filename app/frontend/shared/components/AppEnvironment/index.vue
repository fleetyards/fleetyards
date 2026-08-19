<script lang="ts">
export default {
  name: "AppEnvironment",
};
</script>

<script lang="ts" setup>
import BasePill from "@/shared/components/base/Pill/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";

type Props = {
  gitRevision?: string;
  showInProduction?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  showInProduction: false,
  gitRevision: undefined,
});

const mobile = useMobile();

const route = useRoute();

const environtmentVariant = computed(() => {
  if (window.NODE_ENV === "staging") {
    return PillVariantsEnum.WARNING;
  } else if (window.NODE_ENV === "production") {
    return PillVariantsEnum.DANGER;
  }

  return PillVariantsEnum.DEFAULT;
});

const cssClasses = computed(() => {
  return {
    "app-environment--with-primary-action": route.meta.primaryAction,
  };
});

const nodeEnv = computed(() => {
  return (window.NODE_ENV || "").toUpperCase();
});

const visible = computed(() => {
  return (
    (window.NODE_ENV !== "production" || props.showInProduction) &&
    !mobile.value
  );
});
</script>

<template>
  <div v-if="visible" class="app-environment" :class="cssClasses">
    <BasePill :variant="environtmentVariant">
      <i class="fa-regular fa-info-circle" />
      {{ nodeEnv }}
    </BasePill>
    <BasePill
      v-if="gitRevision"
      :variant="environtmentVariant"
      class="app-environment__git-revision"
    >
      <i class="fa-regular fa-fingerprint" />
      {{ gitRevision }}
    </BasePill>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>

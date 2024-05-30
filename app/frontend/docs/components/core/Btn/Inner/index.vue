<template>
  <div class="panel-btn-inner">
    <template v-if="loading">
      {{ t("actions.loading") }}
      <SmallLoader
        v-if="spinner"
        :loading="loading"
        :alignment="spinnerAlignment"
      />
    </template>
    <template v-else>
      <slot />
    </template>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "@/docs/composables/useI18n";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import type { SpinnerAlignment } from "@/shared/components/SmallLoader/index.vue";

type Props = {
  loading?: boolean;
  spinner?: boolean | SpinnerAlignment;
};

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  spinner: false,
});

const spinnerAlignment = computed(() => {
  if (typeof props.spinner === "boolean") {
    return "right";
  }

  return props.spinner;
});

const { t } = useI18n();
</script>

<script lang="ts">
export default {
  name: "BtnInner",
};
</script>

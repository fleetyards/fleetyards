<script lang="ts">
export default {
  name: "BtnInner",
};
</script>

<script lang="ts" setup>
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import type { SpinnerAlignment } from "@/shared/components/SmallLoader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  loading?: boolean;
  spinner?: boolean | `${SpinnerAlignment}`;
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

<template>
  <div class="panel-btn-inner">
    <template v-if="loading">
      {{ t("baseBtn.labels.loading") }}
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

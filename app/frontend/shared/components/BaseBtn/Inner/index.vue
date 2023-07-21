<template>
  <div class="panel-btn-inner">
    <template v-if="loading">
      {{ i18n?.t("actions.loading") }}
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
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import type { SpinnerAlignment } from "@/shared/components/SmallLoader/index.vue";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

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

const i18n = inject("i18n") as I18nPluginOptions;
</script>

<script lang="ts">
export default {
  name: "BtnInner",
};
</script>

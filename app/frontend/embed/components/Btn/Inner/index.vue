<template>
  <div class="panel-btn-inner">
    <template v-if="loading">
      {{ t("actions.loading") }}
    </template>
    <template v-else>
      <slot />
    </template>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "@/frontend/composables/useI18n";

type Props = {
  loading?: boolean;
};

withDefaults(defineProps<Props>(), {
  loading: false,
});

const { t } = useI18n();
</script>

<script lang="ts">
export default {
  name: "BtnInner",
};
</script>

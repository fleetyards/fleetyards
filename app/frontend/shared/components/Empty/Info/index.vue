<script lang="ts">
export default {
  name: "EmptyInfo",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  queryPresent: boolean;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <p class="text-muted">
    <template v-if="queryPresent">
      {{ t("emptyBox.texts.query") }}
    </template>
    <template v-else>
      {{ t("emptyBox.texts.info") }}
    </template>
  </p>
</template>

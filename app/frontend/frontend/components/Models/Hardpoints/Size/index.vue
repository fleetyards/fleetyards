<script lang="ts">
export default {
  name: "HardpointSize",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  size?: number;
};

withDefaults(defineProps<Props>(), {
  size: undefined,
});

const { t } = useI18n();
</script>

<template>
  <div v-if="size" class="hardpoint-item__size">
    {{ t("labels.hardpoint.size") }} {{ size }}
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>

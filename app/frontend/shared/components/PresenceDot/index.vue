<script lang="ts">
export default {
  name: "PresenceDot",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

interface Props {
  online: boolean;
  /** `on-avatar` overhangs the frame it sits in; `inline` sits in a text row. */
  variant?: "inline" | "on-avatar";
}

const props = withDefaults(defineProps<Props>(), {
  variant: "inline",
});

const { t } = useI18n();

const label = computed(() =>
  props.online ? t("labels.user.online") : t("labels.user.offline"),
);
</script>

<template>
  <span
    v-tooltip="label"
    class="presence-dot"
    :class="[
      `presence-dot-${variant}`,
      { 'presence-dot-online': online, 'presence-dot-offline': !online },
    ]"
    role="img"
    :aria-label="label"
  />
</template>

<style lang="scss" scoped>
@import "index";
</style>

<script lang="ts">
export default {
  name: "BetaBadge",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { isBetaFeature } from "@/shared/utils/BetaFeatures";
import type { FeatureFlagName } from "@/services/fyApi";

type Props = {
  feature: FeatureFlagName | FeatureFlagName[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const visible = computed(() => isBetaFeature(props.feature));
</script>

<template>
  <!--
    Focusable so the explanation is not mouse-only: the tooltip opens on
    keyboard focus as well as hover.
  -->
  <span
    v-if="visible"
    v-tooltip="{ content: t('betaBadge.hint'), multiline: true }"
    class="beta-badge"
    tabindex="0"
    :aria-label="t('betaBadge.hint')"
    data-test="beta-badge"
  >
    {{ t("betaBadge.label") }}
  </span>
</template>

<style lang="scss" scoped>
.beta-badge {
  display: inline-flex;
  flex-shrink: 0;
  align-items: center;
  padding: 2px 6px;
  font-family: "Open Sans", sans-serif;
  font-size: 0.6875rem;
  font-weight: 600;
  line-height: 1.2;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  white-space: nowrap;
  vertical-align: middle;
  cursor: help;
  border-radius: 4px;
  background: color-mix(in srgb, var(--color-warning, #fa6800) 18%, transparent);
  border: 1px solid
    color-mix(in srgb, var(--color-warning, #fa6800) 45%, transparent);
  color: var(--color-warning, #fa6800);
}
</style>

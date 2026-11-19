<script lang="ts">
export default {
  name: "BetaBadge",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { isBetaFeature } from "@/shared/utils/BetaFeatures";
import {
  type FeatureFlagName,
  useBetaFeatures as useBetaFeaturesQuery,
} from "@/services/fyApi";

type Props = {
  feature: FeatureFlagName | FeatureFlagName[];
  // Inside a button or link, which takes the focus and owns the tooltip: a
  // focusable pill in there would be a control nested in a control.
  inControl?: boolean;
  // Sized to sit beside the icon of an icon-only button.
  compact?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  inControl: false,
  compact: false,
});

const { t } = useI18n();

// Which flags have a self-service toggle changes only through /admin/features,
// so one answer serves every pill on the page for a while.
const { data: betaFeatures } = useBetaFeaturesQuery({
  query: { staleTime: 5 * 60 * 1000, retry: false },
});

const visible = computed(() =>
  isBetaFeature(props.feature, betaFeatures.value),
);
</script>

<template>
  <!--
    Focusable so the explanation is not mouse-only: the tooltip opens on
    keyboard focus as well as hover.
  -->
  <span
    v-if="visible && inControl"
    class="beta-badge"
    :class="{ 'beta-badge--compact': compact }"
    data-test="beta-badge"
  >
    {{ t("betaBadge.label") }}
  </span>
  <span
    v-else-if="visible"
    v-tooltip="{ content: t('betaBadge.hint'), multiline: true }"
    class="beta-badge beta-badge--hint"
    :class="{ 'beta-badge--compact': compact }"
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
  border-radius: 4px;
  background: color-mix(
    in srgb,
    var(--color-warning, #fa6800) 18%,
    transparent
  );
  border: 1px solid
    color-mix(in srgb, var(--color-warning, #fa6800) 45%, transparent);
  color: var(--color-warning, #fa6800);
}

.beta-badge--hint {
  cursor: help;
}

.beta-badge--compact {
  padding: 1px 4px;
  font-size: 0.5625rem;
  letter-spacing: 0.02em;
}
</style>

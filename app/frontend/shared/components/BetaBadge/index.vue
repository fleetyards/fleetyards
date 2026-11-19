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
  // Inside a button or link, which takes the focus.
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

const hintId = useId();
</script>
<template>
  <!--
    With a slot, the pill follows what it marks on one wrapping line, and what
    it marks renders unwrapped when the flag is not beta.
  -->
  <span v-if="visible" class="beta-badge-around">
    <slot />
    <!--
      Inside a button or link, which takes the focus, a focusable pill would be
      a control nested in a control, so there it explains on hover only.
    -->
    <span
      v-if="inControl"
      v-tooltip="{ content: t('betaBadge.hint'), multiline: true }"
      class="beta-badge"
      :class="{ 'beta-badge--compact': compact }"
      data-test="beta-badge"
    >
      {{ t("betaBadge.label") }}
    </span>
    <!--
      Focusable so the explanation is not mouse-only: the tooltip opens on
      keyboard focus as well as hover. The hint is a description rather than
      the label, so it stays out of the name of a heading the pill sits in.
    -->
    <template v-else>
      <span
        v-tooltip="{ content: t('betaBadge.hint'), multiline: true }"
        class="beta-badge beta-badge--hint"
        :class="{ 'beta-badge--compact': compact }"
        tabindex="0"
        :aria-describedby="hintId"
        data-test="beta-badge"
      >
        {{ t("betaBadge.label") }}
      </span>
      <span :id="hintId" hidden>{{ t("betaBadge.hint") }}</span>
    </template>
  </span>
  <slot v-else />
</template>

<style lang="scss" scoped>
.beta-badge-around {
  display: inline-flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem;
}

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

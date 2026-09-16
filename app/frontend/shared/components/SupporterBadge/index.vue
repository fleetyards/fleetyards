<script lang="ts">
export default {
  name: "SupporterBadge",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import tier1 from "@/images/supporter/tier-1.png";
import tier2 from "@/images/supporter/tier-2.png";
import tier3 from "@/images/supporter/tier-3.png";

interface Props {
  tier?: number;
  // Rendered as a mark of its own beside the insignia rather than folded into
  // it: the three are raster art whose colour ramp already carries the band, so
  // there is nothing left to restyle for a second meaning.
  recurring?: boolean;
  size?: number;
}

const props = withDefaults(defineProps<Props>(), {
  tier: 0,
  recurring: false,
  size: 24,
});

const { t } = useI18n();

const INSIGNIA: Record<number, string> = {
  1: tier1,
  2: tier2,
  3: tier3,
};

// Tier 0 is everybody who gave nothing this month, so there is no insignia for
// it and the badge renders nothing at all.
const insignia = computed(() => INSIGNIA[props.tier]);

const label = computed(() =>
  props.recurring
    ? t("labels.supporter.tierRecurring", { tier: props.tier })
    : t("labels.supporter.tierBadge", { tier: props.tier }),
);
</script>

<template>
  <span
    v-if="insignia"
    v-tooltip="label"
    class="supporter-badge"
    data-test="supporter-badge"
  >
    <img
      :src="insignia"
      :width="props.size"
      :height="props.size"
      :alt="label"
      class="supporter-badge__insignia"
    />
    <i
      v-if="props.recurring"
      class="fa-duotone fa-arrows-rotate supporter-badge__recurring"
      data-test="supporter-badge-recurring"
      aria-hidden="true"
    />
  </span>
</template>

<style lang="scss" scoped>
.supporter-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  vertical-align: middle;
}

/* The three are the same canvas at different fills, so `contain` keeps them the
   same visual weight rather than letting the widest one sit largest. */
.supporter-badge__insignia {
  object-fit: contain;
}

.supporter-badge__recurring {
  font-size: 0.75em;
  opacity: 0.8;
}
</style>

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
  size?: number;
}

const props = withDefaults(defineProps<Props>(), {
  tier: 0,
  size: 24,
});

const { t } = useI18n();

const INSIGNIA: Record<number, string> = {
  1: tier1,
  2: tier2,
  3: tier3,
};

// Tier 0 is everybody whose month did not reach a euro, so there is no insignia
// for it; callers show their own mark for a supporter below the first band.
const insignia = computed(() => INSIGNIA[props.tier]);

// Deliberately short, and deliberately without the word "supporter": every
// caller puts this beside a visible "Supporter", and repeating it here has
// assistive technology read "Tier 3 supporter Supporter".
const label = computed(() =>
  t("labels.supporter.tierShort", { tier: props.tier }),
);
</script>

<template>
  <span
    v-if="insignia"
    :aria-label="label"
    role="img"
    class="supporter-badge"
    data-test="supporter-badge"
  >
    <img
      :src="insignia"
      :width="props.size"
      :height="props.size"
      alt=""
      aria-hidden="true"
      class="supporter-badge__insignia"
    />
  </span>
</template>

<style lang="scss" scoped>
.supporter-badge {
  display: inline-flex;
  align-items: center;
  vertical-align: middle;
}

/* The three are the same canvas at different fills, so `contain` keeps them the
   same visual weight rather than letting the widest one sit largest. */
.supporter-badge__insignia {
  object-fit: contain;
}
</style>

<script lang="ts">
export default {
  name: "AppNavigationNavItemInner",
};
</script>

<script lang="ts" setup>
import DuotoneGlyph from "@/shared/components/DuotoneGlyph/index.vue";
import { type Glyph, isGlyph } from "@/shared/components/DuotoneGlyph/glyph";
import BetaBadge from "@/shared/components/BetaBadge/index.vue";
import type { FeatureFlagName } from "@/services/fyApi";

type Props = {
  label?: string;
  icon?: string | Glyph;
  image?: string;
  slim?: boolean;
  avatar?: boolean;
  badge?: number;
  feature?: FeatureFlagName | FeatureFlagName[];
};

const props = withDefaults(defineProps<Props>(), {
  label: undefined,
  icon: undefined,
  image: undefined,
  slim: false,
  avatar: false,
  badge: 0,
  feature: undefined,
});

const firstLetter = computed(() => {
  return props.label?.charAt(0);
});

const badgeLabel = computed(() => {
  if (!props.badge) {
    return undefined;
  }

  return props.badge > 99 ? "99+" : String(props.badge);
});
</script>

<template>
  <div
    class="nav-item-inner"
    :class="{
      'nav-item-inner--slim': slim,
    }"
  >
    <span class="nav-item-icon">
      <img
        v-if="image"
        :src="image"
        alt=""
        class="nav-item-image"
        :class="{ 'nav-item-image-avatar': avatar }"
      />
      <DuotoneGlyph v-else-if="isGlyph(icon)" :glyph="icon" />
      <i
        v-else-if="icon"
        :class="{
          [icon]: true,
        }"
        aria-hidden="true"
      />
      <span v-else class="nav-item-image-empty" aria-hidden="true">
        {{ firstLetter }}
      </span>
      <span
        v-if="badgeLabel && slim"
        class="nav-item-badge nav-item-badge--dot"
      >
        {{ badgeLabel }}
      </span>
    </span>
    <span v-if="!slim" class="nav-item-text">
      {{ label }}
    </span>
    <span v-else class="sr-only">{{ label }}</span>
    <BetaBadge v-if="feature && !slim" :feature="feature" />
    <span v-if="badgeLabel && !slim" class="nav-item-badge">
      {{ badgeLabel }}
    </span>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>

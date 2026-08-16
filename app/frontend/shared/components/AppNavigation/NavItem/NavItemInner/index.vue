<script lang="ts">
export default {
  name: "AppNavigationNavItemInner",
};
</script>

<script lang="ts" setup>
type Props = {
  label?: string;
  icon?: string;
  image?: string;
  slim?: boolean;
  avatar?: boolean;
  badge?: number;
};

const props = withDefaults(defineProps<Props>(), {
  label: undefined,
  icon: undefined,
  image: undefined,
  slim: false,
  avatar: false,
  badge: 0,
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
        :alt="`${label} image`"
        class="nav-item-image"
        :class="{ 'nav-item-image-avatar': avatar }"
      />
      <i
        v-else-if="icon"
        :class="{
          [icon]: true,
        }"
      />
      <span v-else class="nav-item-image-empty">
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
    <span v-if="badgeLabel && !slim" class="nav-item-badge">
      {{ badgeLabel }}
    </span>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>

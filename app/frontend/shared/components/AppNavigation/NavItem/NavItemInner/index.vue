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
    </span>
    <span v-if="!slim" class="nav-item-text">
      {{ label }}
    </span>
  </div>
</template>

<script lang="ts" setup>
type Props = {
  label?: string;
  icon?: string;
  image?: string;
  slim?: boolean;
  avatar?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  label: undefined,
  icon: undefined,
  image: undefined,
  slim: false,
  avatar: false,
});

const firstLetter = computed(() => {
  return props.label?.charAt(0);
});
</script>

<script lang="ts">
export default {
  name: "AppNavigationNavItemInner",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>

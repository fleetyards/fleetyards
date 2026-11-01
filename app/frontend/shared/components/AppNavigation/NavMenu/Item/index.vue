<script lang="ts">
export default {
  name: "NavMenuItem",
  // Test ids belong to the link or button, not the list item around it.
  inheritAttrs: false,
};
</script>

<script lang="ts" setup>
import { RouterLink, type RouterLinkProps } from "vue-router";

type Props = {
  to?: RouterLinkProps["to"];
  href?: string;
  action?: () => void;
  label?: string;
  icon?: string;
  image?: string;
  // A count that wants attention, drawn as a badge.
  badge?: number;
  // A count that is only information, drawn as quiet text.
  count?: number;
  active?: boolean;
  divider?: boolean;
  heading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  href: undefined,
  action: undefined,
  label: undefined,
  icon: undefined,
  image: undefined,
  badge: 0,
  count: 0,
  active: false,
  divider: false,
  heading: false,
});

const badgeLabel = computed(() =>
  props.badge > 99 ? "99+" : String(props.badge),
);

const initial = computed(() => props.label?.charAt(0));
</script>

<template>
  <li v-if="divider" class="nav-menu-item__divider" role="separator" />
  <li v-else-if="heading" class="nav-menu-item__heading">{{ label }}</li>
  <li v-else class="nav-menu-item">
    <component
      :is="to ? RouterLink : href ? 'a' : 'button'"
      v-bind="$attrs"
      :to="to"
      :href="href"
      :target="href ? '_blank' : undefined"
      :rel="href ? 'noopener' : undefined"
      :type="to || href ? undefined : 'button'"
      :aria-current="active ? 'page' : undefined"
      class="nav-menu-item__link"
      :class="{ 'nav-menu-item__link--active': active }"
      @click="action?.()"
    >
      <span class="nav-menu-item__icon">
        <img v-if="image" :src="image" alt="" class="nav-menu-item__image" />
        <i v-else-if="icon" :class="icon" />
        <span v-else class="nav-menu-item__initial">{{ initial }}</span>
      </span>
      <span class="nav-menu-item__label">{{ label }}</span>
      <span v-if="badge" class="nav-menu-item__badge">{{ badgeLabel }}</span>
      <span v-else-if="count" class="nav-menu-item__count">{{ count }}</span>
      <i
        v-else-if="active"
        class="nav-menu-item__check fa-solid fa-check"
        aria-hidden="true"
      />
    </component>
  </li>
</template>

<style lang="scss" scoped>
@import "index";
</style>

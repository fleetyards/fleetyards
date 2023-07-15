<template>
  <li v-if="href || to">
    <component :is="itemComponent" v-bind="itemProps" :class="cssClasses">
      <span class="nav-item-icon">
        <slot name="icon">
          <i v-if="icon" :class="icon" />
        </slot>
      </span>
      <span class="nav-item-label">
        <slot />
      </span>
    </component>
  </li>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router/composables";
import type { RawLocation, Location } from "vue-router";

type Props = {
  to?: RawLocation;
  href?: string;
  icon?: string;
  noActive?: boolean;
  active?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  href: undefined,
  icon: undefined,
  active: false,
  noActive: false,
});

const itemComponent = computed(() => {
  if (props.to) {
    return "router-link";
  }

  return "a";
});

const itemProps = computed(() => {
  if (props.to) {
    return {
      to: props.to,
      // activeClass: "bg-indigo-700 text-white",
      exactActiveClass: !props.noActive ? "bg-brand-primary text-white" : "",
    };
  }

  return {
    href: props.href,
  };
});

const route = useRoute();

const isActive = computed(() => {
  if (props.noActive) {
    return false;
  }

  if (props.active) {
    return true;
  }

  if (props.to) {
    if ((props.to as Location).name) {
      return route.name === (props.to as Location).name;
    }

    return route.path === props.to;
  }

  return false;
});

const hoverClasses = computed(() => [
  "hover:text-white",
  "hover:bg-indigo-700",
]);

const cssClasses = computed(() => {
  const classes = [
    "text-lg",
    "text-indigo-200",
    "group",
    "flex",
    "items-center",
    "gap-x-3",
    "rounded-md",
    "p-2",
    "uppercase",
    "leading-6",
  ];

  if (!props.noActive) {
    classes.push(...hoverClasses.value);
  }

  if (isActive.value) {
    classes.push("bg-brand-primary text-white");
  }

  return classes;
});
</script>

<script lang="ts">
export default {
  name: "AppNavigationItem",
};
</script>

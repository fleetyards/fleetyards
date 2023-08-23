<template>
  <li v-if="divider" class="nav-item divider" />
  <li
    v-else-if="hasSubmenuSlot"
    :class="{
      active: active || submenuActive,
      open: open,
    }"
    :data-test="`nav-${String(navKey)}`"
    class="nav-item sub-menu"
  >
    <Collapsed
      v-if="submenuDirection === 'up'"
      :id="`${menuKey}-sub-menu`"
      :visible="open"
      as="ul"
    >
      <slot name="submenu" />
    </Collapsed>
    <button v-tooltip="tooltip" @click="toggleMenu">
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :label="label"
        :icon="icon"
        :image="image"
        :avatar="avatar"
      />
    </button>
    <Collapsed
      v-if="submenuDirection === 'down'"
      :id="`${menuKey}-sub-menu`"
      :visible="open"
      as="ul"
    >
      <slot name="submenu" />
    </Collapsed>
  </li>
  <li
    v-else-if="action"
    :data-test="`nav-${String(navKey)}`"
    class="nav-item"
    @click="action"
  >
    <a v-tooltip="tooltip">
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :label="label"
        :icon="icon"
        :image="image"
        :avatar="avatar"
      />
    </a>
  </li>
  <router-link
    v-else-if="to"
    v-slot="{ href: linkHref, navigate }"
    :to="to"
    :custom="true"
  >
    <li
      role="link"
      :class="{
        active: active || routeActive,
      }"
      :data-test="`nav-${String(navKey)}`"
      class="nav-item"
      :exact="exact"
      @click="navigate"
      @keypress.enter="navigate"
    >
      <a v-tooltip="tooltip" :href="linkHref">
        <slot v-if="hasDefaultSlot" />
        <NavItemInner
          v-else
          :label="label"
          :icon="icon"
          :image="image"
          :avatar="avatar"
        />
      </a>
    </li>
  </router-link>
  <li v-else-if="href" class="nav-item" :data-test="`nav-${String(navKey)}`">
    <a v-tooltip="tooltip" :href="href" target="_blank" rel="noopener">
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :label="label"
        :icon="icon"
        :image="image"
        :avatar="avatar"
      />
    </a>
  </li>
  <li v-else class="nav-item">
    <span>
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :label="label"
        :icon="icon"
        :image="image"
        :avatar="avatar"
      />
    </span>
  </li>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import type { RouteLocationRaw, RouteLocation } from "vue-router";
import Collapsed from "@/shared/components/Collapsed.vue";
import NavItemInner from "./NavItemInner/index.vue";

type Props = {
  to?: RouteLocationRaw;
  action?: () => void;
  href?: string;
  label?: string;
  icon?: string;
  image?: string;
  avatar?: boolean;
  menuKey?: string;
  exact?: boolean;
  divider?: boolean;
  active?: boolean;
  submenuActive?: boolean;
  submenuDirection?: string;
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  action: undefined,
  href: undefined,
  label: undefined,
  icon: undefined,
  image: undefined,
  avatar: false,
  menuKey: undefined,
  exact: false,
  divider: false,
  active: false,
  submenuActive: false,
  submenuDirection: "down",
});

const open = ref(false);

const route = useRoute();

const routeActive = computed(() => {
  if (props.to) {
    return (props.to as RouteLocation).name === route.name;
  }
  return false;
});

const tooltip = computed(() => ({
  content: props.label,
  popperClass: "nav-item-tooltip",
  placement: "right",
}));

const slots = useSlots();

const hasDefaultSlot = computed(() => !!slots.default);

const hasSubmenuSlot = computed(() => !!slots.submenu);

const navKey = computed(() => {
  if (props.menuKey) {
    return props.menuKey;
  }

  if (props.to) {
    return (props.to as RouteLocation).name;
  }

  return "nav-item";
});

watch(
  () => route,
  () => {
    checkRoutes();
  },
  { deep: true },
);

watch(
  () => props.submenuActive,
  () => {
    checkRoutes();
  },
);

onMounted(() => {
  checkRoutes();
});

const checkRoutes = () => {
  open.value = props.submenuActive;
};

const toggleMenu = () => {
  open.value = !open.value;
};
</script>

<script lang="ts">
export default {
  name: "NavItem",
};
</script>

<style lang="scss">
@import "index";
</style>

<template>
  <li v-if="divider" class="nav-item divider" />
  <li
    v-else-if="hasSubmenuSlot"
    :class="{
      active: active || submenuActive,
      open: open,
      'nav-item-slim': slim,
    }"
    :data-test="`nav-${navKey}`"
    class="nav-item sub-menu"
  >
    <BCollapse
      v-if="submenuDirection === 'up'"
      :id="`${menuKey}-sub-menu`"
      :visible="open"
      tag="ul"
    >
      <slot name="submenu" />
    </BCollapse>
    <button v-tooltip="tooltip" @click="toggleMenu">
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :label="label"
        :icon="icon"
        :image="image"
        :avatar="avatar"
        :slim="slim"
      />
      <span
        v-if="!slim"
        class="submenu-icon"
        :class="{ 'submenu-icon-up': submenuDirection === 'up' }"
      >
        <i class="fal fa-chevron-right" />
      </span>
    </button>
    <BCollapse
      v-if="submenuDirection === 'down'"
      :id="`${menuKey}-sub-menu`"
      :visible="open"
      tag="ul"
    >
      <slot name="submenu" />
    </BCollapse>
  </li>
  <li
    v-else-if="action"
    :class="{
      'nav-item-slim': slim,
    }"
    :data-test="`nav-${navKey}`"
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
        :slim="slim"
      />
    </a>
  </li>
  <router-link
    v-else-if="to"
    v-slot="{ href: linkHref, navigate }"
    :to="to"
    :class="{
      active: active || routeActive,
      'nav-item-slim': slim,
    }"
    :data-test="`nav-${navKey}`"
    class="nav-item"
    :exact="exact"
    :custom="true"
  >
    <li role="link" @click="navigate" @keypress.enter="navigate">
      <a v-tooltip="tooltip" :href="linkHref">
        <slot v-if="hasDefaultSlot" />
        <NavItemInner
          v-else
          :label="label"
          :icon="icon"
          :image="image"
          :avatar="avatar"
          :slim="slim"
        />
      </a>
    </li>
  </router-link>
  <li
    v-else-if="href"
    :class="{
      'nav-item-slim': slim,
    }"
    class="nav-item"
    :data-test="`nav-${navKey}`"
  >
    <a v-tooltip="tooltip" :href="href" target="_blank" rel="noopener">
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :label="label"
        :icon="icon"
        :image="image"
        :avatar="avatar"
        :slim="slim"
      />
    </a>
  </li>
  <li
    v-else
    :class="{
      'nav-item-slim': slim,
    }"
    class="nav-item"
  >
    <span>
      <slot v-if="hasDefaultSlot" />
      <NavItemInner
        v-else
        :label="label"
        :icon="icon"
        :image="image"
        :avatar="avatar"
        :slim="slim"
      />
    </span>
  </li>
</template>

<script lang="ts" setup>
import type { Route } from "vue-router";
import { useRoute } from "vue-router";
import { useAppStore } from "@/frontend/stores/App";
import NavItemInner from "./NavItemInner/index.vue";

type Props = {
  to?: Route;
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
  label: "",
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
    return props.to.name === route.name;
  }

  return false;
});

const appStore = useAppStore();

const slim = computed(() => appStore.navSlim && !appStore.mobile);

const tooltip = computed(() => {
  if (!slim.value) {
    return null;
  }

  return {
    content: props.label,
    classes: "nav-item-tooltip",
    placement: "right",
  };
});

const slots = useSlots();

const hasDefaultSlot = computed(() => !!slots.default);

const hasSubmenuSlot = computed(() => !!slots.submenu);

const navKey = computed(() => {
  if (props.menuKey) {
    return props.menuKey;
  }

  if (props.to) {
    return props.to.name;
  }

  return "nav-item";
});

watch(
  () => route,
  () => {
    checkRoutes();
  },
  { deep: true }
);

watch(
  () => props.submenuActive,
  () => {
    checkRoutes();
  }
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

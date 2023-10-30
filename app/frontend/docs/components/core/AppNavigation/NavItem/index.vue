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
    <ul
      v-if="submenuDirection === 'up'"
      :id="`${menuKey}-sub-menu`"
      v-show-slide:400:ease-in-out="open"
    >
      <slot name="submenu" />
    </ul>
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
    <ul
      v-if="submenuDirection === 'down'"
      :id="`${menuKey}-sub-menu`"
      v-show-slide:400:ease-in-out="open"
      :visible="open"
    >
      <slot name="submenu" />
    </ul>
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
import { useRoute } from "vue-router/composables";
import type { RawLocation, Location } from "vue-router";
import Store from "@/frontend/lib/Store";
import NavItemInner from "./NavItemInner/index.vue";

type Props = {
  to?: RawLocation;
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

const mobile = computed(() => Store.getters.mobile);

const navSlim = computed(() => Store.getters["app/navSlim"]);

const slim = computed(() => navSlim.value && !mobile.value);

const routeActive = computed(() => {
  if (props.to) {
    return (props.to as Location).name === route.name;
  }
  return false;
});

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
    return (props.to as Location).name;
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

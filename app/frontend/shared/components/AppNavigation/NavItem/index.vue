<template>
  <li v-if="divider" class="nav-item__divider" />
  <li
    v-else-if="hasSubmenuSlot"
    :class="{
      'nav-item__sub-menu--active': active || submenuActive,
      'nav-item__sub-menu--open': open,
      'nav-item--slim': slim,
    }"
    :data-test="`nav-${navKey}`"
    class="nav-item nav-item__sub-menu"
  >
    <Collapsed
      v-if="submenuDirection === 'up'"
      :id="`${menuKey}-sub-menu`"
      as="ul"
      :visible="open"
    >
      <li class="nav-item__divider" />
      <slot name="submenu" />
      <li class="nav-item__divider" />
    </Collapsed>
    <button v-tooltip="tooltip" @click="toggleMenu">
      <slot>
        <NavItemInner
          :label="label"
          :icon="icon"
          :image="image"
          :avatar="avatar"
          :slim="slim"
        />
        <span
          v-if="!slim"
          class="nav-item__submenu-icon"
          :class="{ 'nav-item__submenu-icon--up': submenuDirection === 'up' }"
        >
          <i class="fas fa-chevron-right" />
        </span>
      </slot>
    </button>
    <Collapsed
      v-if="submenuDirection === 'down'"
      :id="`${menuKey}-sub-menu`"
      :visible="open"
      as="ul"
    >
      <li class="nav-item__divider" />
      <slot name="submenu" />
      <li class="nav-item__divider" />
    </Collapsed>
  </li>
  <li
    v-else-if="action"
    :class="{
      'nav-item--slim': slim,
    }"
    :data-test="`nav-${navKey}`"
    class="nav-item"
    @click="action"
  >
    <a v-tooltip="tooltip">
      <slot>
        <NavItemInner
          :label="label"
          :icon="icon"
          :image="image"
          :avatar="avatar"
          :slim="slim"
        />
      </slot>
    </a>
  </li>
  <router-link
    v-else-if="to"
    v-slot="{ href: linkHref, navigate }"
    :to="to"
    custom
  >
    <li
      role="link"
      :class="{
        'nav-item--active': active || routeActive,
        'nav-item--slim': slim,
      }"
      :data-test="`nav-${navKey}`"
      class="nav-item"
      @click="navigate"
      @keypress.enter="() => navigate"
    >
      <a v-tooltip="tooltip" :href="linkHref">
        <slot>
          <NavItemInner
            :label="label"
            :icon="icon"
            :image="image"
            :avatar="avatar"
            :slim="slim"
          />
        </slot>
      </a>
    </li>
  </router-link>
  <li
    v-else-if="href"
    :class="{
      'nav-item--slim': slim,
    }"
    class="nav-item"
    :data-test="`nav-${navKey}`"
  >
    <a v-tooltip="tooltip" :href="href" target="_blank" rel="noopener">
      <slot>
        <NavItemInner
          :label="label"
          :icon="icon"
          :image="image"
          :avatar="avatar"
          :slim="slim"
        />
      </slot>
    </a>
  </li>
  <li
    v-else
    :class="{
      'nav-item--slim': slim,
    }"
    class="nav-item"
  >
    <span>
      <slot>
        <NavItemInner
          :label="label"
          :icon="icon"
          :image="image"
          :avatar="avatar"
          :slim="slim"
        />
      </slot>
    </span>
  </li>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import type { RouteLocationNamedRaw, RouterLinkProps } from "vue-router";
import NavItemInner from "./NavItemInner/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import Collapsed from "@/shared/components/Collapsed.vue";
import { storeToRefs } from "pinia";
import { useNavStore } from "@/shared/stores/nav";

type Props = {
  to?: RouterLinkProps["to"];
  action?: () => void;
  href?: string;
  label?: string;
  icon?: string;
  image?: string;
  avatar?: boolean;
  menuKey?: string;
  divider?: boolean;
  active?: boolean;
  prefix?: string;
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
  divider: false,
  active: false,
  prefix: undefined,
  submenuActive: false,
  submenuDirection: "down",
});

const open = ref(false);

const route = useRoute();

const mobile = useMobile();

const navStore = useNavStore();

const { slim: navSlim } = storeToRefs(navStore);

const slim = computed(() => navSlim.value && !mobile.value);

const routeActive = computed(() => {
  if (props.to) {
    return (props.to as RouteLocationNamedRaw).name === route.name;
  }
  return false;
});

const tooltip = computed(() => {
  if (!slim.value) {
    return null;
  }

  return {
    content: props.label,
    popperClass: "nav-item-tooltip",
    placement: "right",
  };
});

const slots = useSlots();

const hasSubmenuSlot = computed(() => !!slots.submenu);

const navKey = computed(() => {
  if (props.menuKey) {
    return props.menuKey;
  }

  if (props.to && (props.to as RouteLocationNamedRaw).name) {
    return String((props.to as RouteLocationNamedRaw).name);
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

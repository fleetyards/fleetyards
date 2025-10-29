<script lang="ts">
export default {
  name: "AppNavigation",
};
</script>

<script lang="ts" setup>
import NavItem from "./NavItem/index.vue";
import NavFooter from "./NavFooter/index.vue";
import { useNavStore } from "@/shared/stores/nav";
import { storeToRefs } from "pinia";

type Props = {
  title: string;
  logo: string;
};

defineProps<Props>();

const navStore = useNavStore();

const { slimNavigation: slim, collapsed: navCollapsed } = storeToRefs(navStore);

const route = useRoute();

watch(
  () => route.path,
  () => {
    closeNav();
  },
);

onMounted(() => {
  document.addEventListener("click", documentClick);
});

onBeforeUnmount(() => {
  document.removeEventListener("click", documentClick);

  closeNav();
});

const navigation = ref<HTMLElement | null>(null);

const documentClick = (event: Event) => {
  const element = navigation.value;
  const { target } = event;

  if (element !== target && !element?.contains(target as Node)) {
    closeNav();
  }
};

const closeNav = () => {
  navStore.close();
};
</script>

<template>
  <nav
    ref="navigation"
    :class="{
      visible: !navCollapsed,
      'app-navigation--slim': slim,
    }"
    class="app-navigation"
    role="navigation"
  >
    <div
      :class="{
        'app-navigation__wrapper--slim': slim,
      }"
      class="app-navigation__wrapper"
    >
      <div class="app-navigation__inner">
        <ul>
          <NavItem class="logo-menu">
            <img v-lazy="logo" class="logo-menu-image" alt="logo" />
            <span v-if="!slim" class="logo-menu-label">
              {{ title }}
            </span>
          </NavItem>
          <slot name="main" />
        </ul>
        <NavFooter>
          <template #default>
            <slot name="footer" />
          </template>
        </NavFooter>
      </div>
    </div>
  </nav>
</template>

<style lang="scss" scoped>
@import "index";
</style>

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
import { useMobileStore } from "@/shared/stores/mobile";
import { useSwipeToDismiss } from "@/shared/composables/useSwipeToDismiss";

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
  document.body.classList.remove("nav-swiping");

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

const wrapper = ref<HTMLElement | null>(null);

const { mobile } = storeToRefs(useMobileStore());

const { offset: swipeOffset, dragging } = useSwipeToDismiss({
  panel: wrapper,
  side: "right",
  enabled: () => mobile.value && !navCollapsed.value,
  onDismiss: closeNav,
});

/*
 * On the body, because the page, its header and the tab bar all make room for
 * the drawer and have to follow the finger with it - see `.nav-swiping`.
 */
watchEffect(() => {
  document.body.classList.toggle("nav-swiping", dragging.value);
  document.body.style.setProperty(
    "--nav-swipe-offset",
    `${swipeOffset.value}px`,
  );
});
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
    data-test="app-navigation"
  >
    <div
      ref="wrapper"
      :class="{
        'app-navigation__wrapper--slim': slim,
      }"
      class="app-navigation__wrapper"
    >
      <div class="app-navigation__inner">
        <ul>
          <NavItem class="logo-menu">
            <img :src="logo" class="logo-menu-image" alt="logo" />
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

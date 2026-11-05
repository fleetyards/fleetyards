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
import { useI18n } from "@/shared/composables/useI18n";
import { containTab, moveRowFocus, navRows } from "./keyboard";

type Props = {
  title: string;
  logo: string;
};

defineProps<Props>();

const { t } = useI18n();

const navStore = useNavStore();

const { slimNavigation: slim, collapsed: navCollapsed } = storeToRefs(navStore);

const route = useRoute();

/*
 * A navigation can swap the rail itself -- entering a fleet replaces its rows
 * with the fleet's -- and the row holding the focus goes with them. The switcher
 * at the head of the rail is what stays.
 */
watch(
  () => route.path,
  async () => {
    const hadFocus = navigation.value?.contains(document.activeElement);

    closeNav();

    await nextTick();

    if (hadFocus && document.activeElement === document.body) {
      focusFirstRow();
    }
  },
);

onMounted(() => {
  document.addEventListener("click", documentClick);
});

onBeforeUnmount(() => {
  document.removeEventListener("click", documentClick);
  window.removeEventListener("keydown", onDrawerKeydown);
  document.body.classList.remove("nav-swiping");
  document.body.style.removeProperty("--nav-swipe-offset");

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

const drawerHidden = computed(() => mobile.value && navCollapsed.value);

const onDrawerKeydown = (event: KeyboardEvent) => {
  containTab(event, wrapper.value);

  // On the window, so a menu open inside the drawer hears Escape first.
  if (event.key === "Escape" && !event.defaultPrevented) {
    closeNav();
  }
};

let focusBeforeDrawer: HTMLElement | null = null;

const focusFirstRow = () => {
  navRows(wrapper.value?.querySelector(".app-navigation__inner"))[0]?.focus({
    preventScroll: true,
  });
};

watch(navCollapsed, async (collapsed) => {
  if (collapsed) {
    window.removeEventListener("keydown", onDrawerKeydown);

    // A row keeping the focus would lose it once the drawer turns inert.
    if (wrapper.value?.contains(document.activeElement)) {
      focusBeforeDrawer?.focus({ preventScroll: true });
    }

    focusBeforeDrawer = null;

    return;
  }

  if (!mobile.value) {
    return;
  }

  focusBeforeDrawer = document.activeElement as HTMLElement | null;
  window.addEventListener("keydown", onDrawerKeydown);

  await nextTick();

  focusFirstRow();
});

// Focusable only for the jump. A lasting tabindex would catch every press on
// something in the page that takes no focus of its own, and the popovers that
// read a press going nowhere as a press inside them would start closing.
const skipToContent = () => {
  const main = document.getElementById("main-content");

  if (!main) {
    return;
  }

  main.tabIndex = -1;
  main.addEventListener("blur", () => main.removeAttribute("tabindex"), {
    once: true,
  });
  main.focus();
};

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
    :aria-label="t('nav.navigation')"
    data-test="app-navigation"
    @keydown="moveRowFocus"
  >
    <a
      class="app-navigation__skip"
      href="#main-content"
      data-test="nav-skip-to-content"
      @click.prevent="skipToContent"
    >
      {{ t("nav.skipToContent") }}
    </a>
    <div
      ref="wrapper"
      :class="{
        'app-navigation__wrapper--slim': slim,
      }"
      :inert="drawerHidden || undefined"
      class="app-navigation__wrapper"
    >
      <div class="app-navigation__inner">
        <ul>
          <!-- An app may make the logo do something; the plain row is the
               default. -->
          <slot name="logo">
            <NavItem class="logo-menu">
              <img :src="logo" class="logo-menu-image" alt="logo" />
              <span v-if="!slim" class="logo-menu-label">
                {{ title }}
              </span>
            </NavItem>
          </slot>
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

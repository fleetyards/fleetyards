<script lang="ts">
export default {
  name: "OffCanvas",
};
</script>

<script lang="ts" setup>
import { defineAsyncComponent } from "vue";
import type { Raw } from "vue";
import { useComlink } from "@/shared/composables/useComlink";
import { type OffCanvasOptions } from "./types";

const visible = ref(false);
const title = ref<string | undefined>();
const side = ref<"left" | "right">("left");
const component = ref<Raw<Component> | undefined>();
const componentProps = ref({});

const comlink = useComlink();

const onOpenComlink = ref();
const onCloseComlink = ref();

onMounted(() => {
  onOpenComlink.value = comlink.on("open-off-canvas", open);
  onCloseComlink.value = comlink.on("close-off-canvas", close);
});

onUnmounted(() => {
  onOpenComlink.value();
  onCloseComlink.value();
  resetState();
});

const panel = ref<HTMLElement | null>(null);

const getAppContent = () =>
  document.querySelector<HTMLElement>(".app-content");

const getMobileNav = () =>
  document.querySelector<HTMLElement>(".navigation-mobile");

const resetState = () => {
  const appContent = getAppContent();
  if (appContent) {
    appContent.style.transform = "";
  }
  const mobileNav = getMobileNav();
  if (mobileNav) {
    mobileNav.style.transform = "";
  }
  document.body.classList.remove("no-scroll");
  document.documentElement.style.overflow = "";
};

const open = async (options: OffCanvasOptions) => {
  title.value = options.title;
  side.value = options.side || "left";
  componentProps.value = options.props || {};
  component.value = markRaw(defineAsyncComponent(options.component));

  visible.value = true;

  const shiftPx = side.value === "left" ? 300 : -300;
  const appContent = getAppContent();
  if (appContent) {
    appContent.style.transform = `translateX(${shiftPx}px)`;
  }
  const mobileNav = getMobileNav();
  if (mobileNav) {
    mobileNav.style.transform = `translateX(${shiftPx}px)`;
  }

  document.body.classList.add("no-scroll");
  document.documentElement.style.overflow = "hidden";

  await nextTick(() => {
    document.addEventListener("click", onDocumentClick);
  });
};

const close = () => {
  document.removeEventListener("click", onDocumentClick);
  visible.value = false;

  const appContent = getAppContent();
  if (appContent) {
    appContent.style.transform = "translateX(0)";
  }
  const mobileNav = getMobileNav();
  if (mobileNav) {
    mobileNav.style.transform = "translateX(0)";
  }

  setTimeout(() => {
    component.value = undefined;
    componentProps.value = {};

    document.body.classList.remove("no-scroll");
    document.documentElement.style.overflow = "";

    requestAnimationFrame(() => {
      // Suppress transitions during cleanup to prevent flicker
      if (appContent) {
        appContent.style.transition = "none";
        appContent.style.transform = "";
        void appContent.offsetHeight;
        appContent.style.transition = "";
      }
      if (mobileNav) {
        mobileNav.style.transition = "none";
        mobileNav.style.transform = "";
        void mobileNav.offsetHeight;
        mobileNav.style.transition = "";
      }
    });
  }, 550);
};

const onDocumentClick = (event: Event) => {
  if (!visible.value) return;
  if (panel.value?.contains(event.target as Node)) return;

  close();
};
</script>

<template>
  <Teleport to="body">
    <transition name="off-canvas-backdrop">
      <div
        v-if="visible"
        class="off-canvas__backdrop"
        @click="close"
      />
    </transition>
    <nav
      ref="panel"
      class="off-canvas__panel"
      :class="{
        visible: visible,
        'off-canvas__panel--left': side === 'left',
        'off-canvas__panel--right': side === 'right',
      }"
    >
      <div v-if="title" class="off-canvas__header">
        <span class="off-canvas__title">{{ title }}</span>
      </div>
      <div class="off-canvas__body">
        <Component
          v-if="component"
          :is="component"
          v-bind="componentProps"
          @close="close"
        />
      </div>
    </nav>
  </Teleport>
</template>

<style lang="scss" scoped>
@import "index";
</style>

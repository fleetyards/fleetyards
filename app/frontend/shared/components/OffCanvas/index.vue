<script lang="ts">
export default {
  name: "OffCanvas",
};
</script>

<script lang="ts" setup>
import { useComlink } from "@/shared/composables/useComlink";
import { type OffCanvasOptions } from "./types";

const isShow = ref(false);
const isOpen = ref(false);
const title = ref<string | undefined>();
const side = ref<"left" | "right">("left");

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
});

const panel = ref<HTMLElement | null>(null);

const open = async (options: OffCanvasOptions) => {
  title.value = options.title;
  side.value = options.side || "left";

  isShow.value = true;

  document.body.classList.add("no-scroll");
  document.documentElement.style.overflow = "hidden";

  await nextTick(() => {
    setTimeout(() => {
      isOpen.value = true;

      document.addEventListener("click", onDocumentClick);
    }, 50);
  });
};

const close = () => {
  document.removeEventListener("click", onDocumentClick);

  isOpen.value = false;

  setTimeout(() => {
    isShow.value = false;

    document.body.classList.remove("no-scroll");
    document.documentElement.style.overflow = "";

    comlink.emit("off-canvas-closed");
  }, 500);
};

const onDocumentClick = (event: Event) => {
  if (!isOpen.value) return;
  if (panel.value?.contains(event.target as Node)) return;

  close();
};

const panelClasses = computed(() => {
  return {
    show: isShow.value,
    in: isOpen.value,
    "off-canvas__panel--left": side.value === "left",
    "off-canvas__panel--right": side.value === "right",
  };
});
</script>

<template>
  <Teleport to="body">
    <transition name="off-canvas-backdrop">
      <div v-if="isShow" class="off-canvas__backdrop" @click="close" />
    </transition>
    <nav ref="panel" class="off-canvas__panel" :class="panelClasses">
      <div v-if="title" class="off-canvas__header">
        <span class="off-canvas__title">{{ title }}</span>
      </div>
      <div id="off-canvas-content" class="off-canvas__body" />
    </nav>
  </Teleport>
</template>

<style lang="scss" scoped>
@import "index";
</style>

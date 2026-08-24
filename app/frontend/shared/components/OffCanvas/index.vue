<script lang="ts">
export default {
  name: "OffCanvas",
};
</script>

<script lang="ts" setup>
import { useComlink } from "@/shared/composables/useComlink";
import { type OffCanvasOptions } from "./types";
import { afterNextPaint } from "@/shared/utils/Transitions";

// Matches the panel's transition duration in index.scss.
const CLOSE_DURATION = 500;

const isShow = ref(false);

/*
 * Set while the panel is being moved to the side it will open from. Flipping the
 * side class swaps `translateX(-100%)` for `translateX(100%)`, and `transform`
 * is transitioned - so without suppressing it the panel travels between the two
 * start positions, passing through the middle of the viewport on the way. That
 * is the "slides in from the centre" everyone saw.
 */
const positioning = ref(false);
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
  const nextSide = options.side || "left";

  /*
   * Switching sides while open cannot be animated in place: `left` and `right`
   * change instantly while only `transform` transitions, so the panel would jump
   * to the far edge and then slide in from the wrong direction. Closing first
   * costs the leave transition and gets the entrance right.
   */
  if (isOpen.value && nextSide !== side.value) {
    close();
    await new Promise((resolve) => setTimeout(resolve, CLOSE_DURATION));
  }

  title.value = options.title;

  positioning.value = true;
  side.value = nextSide;

  isShow.value = true;

  document.body.classList.add("no-scroll");
  document.documentElement.style.overflow = "hidden";

  await nextTick();

  // Two paints, both load-bearing: the first settles the start position with the
  // transition switched off, the second lets `in` animate away from it.
  afterNextPaint(() => {
    positioning.value = false;

    afterNextPaint(() => {
      isOpen.value = true;

      document.addEventListener("click", onDocumentClick);
    });
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
  }, CLOSE_DURATION);
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
    "off-canvas__panel--positioning": positioning.value,
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

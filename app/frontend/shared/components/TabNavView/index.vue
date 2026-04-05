<script lang="ts">
export default {
  name: "TabNavView",
};
</script>

<script lang="ts" setup>
import { useMobile } from "@/shared/composables/useMobile";

const mobile = useMobile();
const tabsEl = ref<HTMLElement | null>(null);
const route = useRoute();

const scrollToActive = (smooth = true) => {
  if (!mobile.value) return;

  const container = tabsEl.value;
  if (!container) return;

  const activeEl = container.querySelector<HTMLElement>("li.active");
  if (!activeEl) return;

  const containerRect = container.getBoundingClientRect();
  const elRect = activeEl.getBoundingClientRect();

  const scrollLeft =
    activeEl.offsetLeft - containerRect.width / 2 + elRect.width / 2;

  container.scrollTo({
    left: scrollLeft,
    behavior: smooth ? "smooth" : "instant",
  });
};

onMounted(() => {
  void nextTick(() => scrollToActive(false));
});

watch(
  () => route.name,
  () => {
    void nextTick(() => scrollToActive(true));
  },
);
</script>

<template>
  <div class="row">
    <div class="col-12 col-md-3 order-md-12 tabs-wrapper">
      <ul ref="tabsEl" class="tabs">
        <slot name="nav"></slot>
      </ul>
    </div>
    <div class="col-12 col-md-9 order-md-1">
      <slot name="content">
        <router-view />
      </slot>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>

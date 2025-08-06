<template>
  <div
    :key="`${backgroundImageKey}-${uuid}`"
    class="app-background"
    :class="{
      [backgroundImageKey]: true,
      webp: webpSupported,
    }"
  />
</template>

<script lang="ts" setup>
import { v4 as uuidv4 } from "uuid";
import { useRoute } from "vue-router";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";

const backgroundImageFallback = "bg-6";

const uuid = ref<string>(uuidv4());

const { supported: webpSupported } = useWebpCheck();

const route = useRoute();

const backgroundImageKey = computed(() => {
  if (route.meta?.backgroundImage) {
    return route.meta.backgroundImage;
  }

  return backgroundImageFallback;
});

onMounted(() => {
  uuid.value = uuidv4();
});
</script>

<script lang="ts">
export default {
  name: "BackgroundImage",
};
</script>

<style lang="scss" scoped>
.app-background {
  position: fixed;
  z-index: -1;
  width: 100vw;
  height: 100vh;
  background-color: black;
  background-repeat: no-repeat;
  background-position: center;
  background-size: cover;
  opacity: 0.4;
  transition: background-image ease 0.5s;

  &.bg-0 {
    background-image: url("@/images/bg-0.jpg");

    &.webp {
      background-image: url("@/images/bg-0.webp");
    }
  }

  &.bg-2 {
    background-image: url("@/images/bg-2.jpg");

    &.webp {
      background-image: url("@/images/bg-2.webp");
    }
  }

  &.bg-5 {
    background-image: url("@/images/bg-5.jpg");

    &.webp {
      background-image: url("@/images/bg-5.webp");
    }
  }

  &.bg-6 {
    background-image: url("@/images/bg-6.jpg");

    &.webp {
      background-image: url("@/images/bg-6.webp");
    }
  }

  &.bg-7 {
    background-image: url("@/images/bg-7.jpg");

    &.webp {
      background-image: url("@/images/bg-7.webp");
    }
  }

  &.bg-8 {
    background-image: url("@/images/bg-8.jpg");

    &.webp {
      background-image: url("@/images/bg-8.webp");
    }
  }

  &.bg-404 {
    background-image: url("@/images/bg-404.jpg");

    &.webp {
      background-image: url("@/images/bg-404.webp");
    }
  }
}
</style>

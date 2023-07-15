<template>
  <div
    :key="`${backgroundImageKey}-${uuid}`"
    class="background-image"
    :class="{
      [backgroundImageKey]: true,
      webp: webpSupported,
    }"
  />
</template>

<script lang="ts" setup>
import { v4 as uuidv4 } from "uuid";
import { useRoute } from "vue-router/composables";
import { useWebpCheck } from "@/frontend/composables/useWebpCheck";
import Store from "@/frontend/lib/Store";

const backgroundImageFallback = "bg-6";

const uuid = ref<string>(uuidv4());

const { supported: webpSupported } = useWebpCheck();

const route = useRoute();

const notFound = computed(() => Store.getters.notFound);

const backgroundImageKey = computed(() => {
  if (notFound.value) {
    return "bg-404";
  }

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

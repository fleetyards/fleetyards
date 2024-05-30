<template>
  <LazyImage
    :key="src"
    :src="src"
    :alt="alt"
    :title="title || alt"
    :href="href"
    class="image gallery-image"
    @click.ctrl.prevent="openInNewTab(href)"
    @click.meta.prevent="openInNewTab(href)"
  />
</template>

<script lang="ts" setup>
import LazyImage from "@/shared/components/LazyImage/index.vue";

type Props = {
  src: string;
  alt?: string;
  title?: string;
  href?: string;
};

withDefaults(defineProps<Props>(), {
  alt: "image",
  title: undefined,
  href: undefined,
});

const openInNewTab = (url?: string) => {
  if (!url) return;

  window.open(url, "_blank");
};
</script>

<script lang="ts">
export default {
  name: "BaseImage",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>

<template>
  <a
    :href="href"
    :data-pswp-src="href"
    :data-pswp-width="width"
    :data-pswp-height="height"
    :data-pswp-cropped="true"
    target="_blank"
    class="image gallery-image lazy-image"
  >
    <img v-lazy="src" :alt="alt" :title="title || alt" />
    <!-- eslint-disable-next-line -->
    <div v-if="caption" class="hidden-caption-content" v-html="caption" />
  </a>
</template>

<script lang="ts" setup>
type Props = {
  src: string;
  alt?: string;
  title?: string;
  href?: string;
  width?: number;
  height?: number;
  caption?: string;
};

withDefaults(defineProps<Props>(), {
  alt: "image",
  title: undefined,
  href: undefined,
  width: undefined,
  height: undefined,
  caption: undefined,
});
</script>

<script lang="ts">
export default {
  name: "BaseImage",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>

<script lang="ts">
export default {
  name: "BaseMarkdown",
};
</script>

<script lang="ts" setup>
import { renderMarkdown } from "@/shared/utils/Markdown";

type Props = {
  source?: string;
};

const props = withDefaults(defineProps<Props>(), {
  source: "",
});

const html = computed(() => renderMarkdown(props.source));
</script>

<template>
  <!-- eslint-disable-next-line vue/no-v-html -- renderMarkdown escapes every character it does not turn into a tag -->
  <div class="markdown markdown-content" v-html="html" />
</template>

<style lang="scss">
@import "./content";
</style>

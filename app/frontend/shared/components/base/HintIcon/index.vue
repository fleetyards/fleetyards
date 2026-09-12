<script lang="ts">
export default {
  name: "HintIcon",
};
</script>

<script lang="ts" setup>
type Props = {
  text: string;
};

const props = defineProps<Props>();
</script>

<template>
  <!--
    Focusable so the hint is not mouse-only: the tooltip opens on keyboard focus
    as well as hover, and the label repeats it for anything that reads the tree
    rather than pointing at it.

    `multiline` because a hint is a sentence: nothing wraps a tooltip by
    default, and an unwrapped one runs off the side of the window.
  -->
  <i
    v-tooltip="{ content: props.text, multiline: true }"
    class="fa-light fa-info-circle hint-icon"
    :aria-label="props.text"
    tabindex="0"
  />
</template>

<style lang="scss" scoped>
.hint-icon {
  cursor: help;
}
</style>

<script lang="ts">
export default {
  name: "PanelTag",
};
</script>

<template>
  <button type="button" class="panel-tag">
    <slot />
  </button>
</template>

<style lang="scss" scoped>
/*
 * The tag is the control, rather than a div wrapping a Btn: Btn is sized for a
 * toolbar - 43px tall with a fixed 15px label - so it, not the tag, was setting
 * the height, and its hover tint painted a second, inset box inside the blue.
 * Restyling that from the outside meant reaching into another component with
 * :deep.
 */
.panel-tag {
  position: absolute;
  bottom: 10px;
  right: 0;
  display: flex;
  align-items: center;
  gap: 6px;
  // Same box as .model-panel-on-sale, the other tag pinned to these panels, so
  // the two read as one family rather than two sizes of badge.
  height: 40px;
  margin: 0;
  padding: 0 12px;
  background-color: $primary;
  border: 0;
  border-radius: 10px 0 0 10px;
  color: #fff;
  font-size: 13px;
  line-height: 1.4;
  white-space: nowrap;
  text-decoration: none;
  cursor: pointer;
  transition: background-color 0.15s ease-in-out;
}

.panel-tag:hover {
  background-color: color.adjust($primary, $lightness: 8%);
  color: #fff;
}

.panel-tag:focus-visible {
  outline: 2px solid #fff;
  outline-offset: -4px;
}
</style>

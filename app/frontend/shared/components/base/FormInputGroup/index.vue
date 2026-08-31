<script lang="ts">
export default {
  name: "FormInputGroup",
};
</script>

<script lang="ts" setup></script>

<template>
  <div class="form-input-group">
    <slot />
  </div>
</template>

<style lang="scss" scoped>
.form-input-group {
  display: flex;
  align-items: flex-end;
  gap: 5px;
  margin-bottom: 1rem;

  :deep(.base-input) {
    flex: 1 1 auto;
    min-width: 0;
    margin-bottom: 0;
  }

  // No height override: Btn's own sizes match the form controls (sm 43px like
  // .base-input, lg 55px like .base-input--large), so forcing 43px here would
  // clamp a lg button next to a large input - which is what broke the hero
  // search field.
  :deep(.btn),
  :deep(.oauth-btn) {
    flex-shrink: 0;
    white-space: nowrap;

    /*
     * No offset needed: flex-end aligns the bottoms, and a field's bottom is
     * its control's again now that the message collapses to nothing until there
     * is one. While the line was reserved, this had to drop the button by
     * exactly that line's height to keep the two level.
     */
  }
}
</style>

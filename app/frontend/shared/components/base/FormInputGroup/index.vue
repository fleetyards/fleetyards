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
     * flex-end aligns the bottoms, and a field's bottom is no longer its
     * control's: every control now reserves a line for its message whether or
     * not it has one, so the button was dropping by exactly that line's height.
     *
     * Read from the same tokens the message itself uses, so the two cannot
     * disagree -- the label alignment on checkboxes is done the same way, for
     * the same reason.
     */
    margin-bottom: calc(
      var(--field-message-line, 1.25rem) + var(--field-message-gap, 4px)
    );
  }
}
</style>

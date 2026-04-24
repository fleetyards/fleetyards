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

  :deep(.panel-btn),
  :deep(.oauth-btn) {
    flex-shrink: 0;
    white-space: nowrap;
    height: 43px;
    margin: 0;
  }
}
</style>

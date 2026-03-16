<script lang="ts">
export default {
  name: "PrimaryAction",
};
</script>

<script lang="ts" setup>
type Props = {
  action?: () => void;
  icon?: string;
  label?: string;
};

withDefaults(defineProps<Props>(), {
  action: undefined,
  icon: "fa-light fa-plus",
  label: undefined,
});
</script>

<template>
  <transition name="back-to-top-fade">
    <div v-if="action" class="primary-action">
      <div
        v-tooltip="label"
        :aria-label="label"
        class="primary-action-item"
        @click="action"
      >
        <div class="primary-action-inner">
          <i :class="icon" />
        </div>
      </div>
    </div>
  </transition>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>

<template>
  <transition name="back-to-top-fade">
    <div class="primary-action">
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

<script lang="ts" setup>
type Props = {
  action: () => void;
  icon?: string;
  label?: string;
};

withDefaults(defineProps<Props>(), {
  icon: "fal fa-plus",
  label: undefined,
});
</script>

<script lang="ts">
export default {
  name: "PrimaryAction",
};
</script>

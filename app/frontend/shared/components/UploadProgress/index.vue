<script lang="ts">
export default {
  name: "UploadProgress",
};
</script>

<script lang="ts" setup>
type Props = {
  progress?: number;
  active?: boolean;
  error?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  progress: 0,
  active: false,
  error: false,
});

const fillClasses = computed(() => ({
  "upload-progress__fill": true,
  "upload-progress__fill--striped": true,
  "upload-progress__fill--animated": props.active,
  "upload-progress__fill--error": props.error,
}));
</script>

<template>
  <div class="upload-progress">
    <div :class="fillClasses" role="progressbar" :style="{ width: progress + '%' }">
      {{ progress }} %
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>

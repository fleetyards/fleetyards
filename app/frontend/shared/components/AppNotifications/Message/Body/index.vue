<script lang="ts">
export default {
  name: "AppNotificationsMessageBody",
};
</script>

<script lang="ts" setup>
type Props = {
  text?: string;
};

withDefaults(defineProps<Props>(), {
  text: undefined,
});
</script>

<template>
  <div class="app-notifications__message-body">
    <div class="app-notifications__message-body__inner">
      <!-- eslint-disable-next-line vue/no-v-html -->
      <span v-if="text" v-html="text" />
      <slot v-else />
    </div>

    <div class="app-notifications__message-body__close">
      <i class="fal fa-times" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>

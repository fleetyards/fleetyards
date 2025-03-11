<script lang="ts">
export default {
  name: "AppNotificationsMessageBody",
};
</script>

<script lang="ts" setup></script>

<template>
  <div class="app-notifications__message-body">
    <div class="app-notifications__message-body__inner">
      <slot />
    </div>

    <div class="app-notifications__message-body__close">
      <i class="fal fa-times" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>

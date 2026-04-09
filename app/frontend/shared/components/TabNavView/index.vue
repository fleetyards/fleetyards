<script lang="ts">
export default {
  name: "TabNavView",
};
</script>

<template>
  <div class="row">
    <div class="col-12 col-md-9">
      <slot name="content">
        <router-view />
      </slot>
    </div>
    <div class="col-12 col-md-3">
      <ul class="tabs">
        <slot name="nav"></slot>
      </ul>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>

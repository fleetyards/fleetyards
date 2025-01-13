<script lang="ts">
export default {
  name: "TabNavView",
};
</script>

<template>
  <div class="row">
    <div class="col-12 col-md-3 order-md-12">
      <ul class="tabs">
        <slot name="nav"></slot>
      </ul>
    </div>
    <div class="col-12 col-md-9 order-md-1">
      <slot name="content"></slot>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>

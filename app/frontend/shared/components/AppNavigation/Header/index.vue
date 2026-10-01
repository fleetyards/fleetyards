<script lang="ts">
export default {
  name: "AppNavigationHeader",
};
</script>

<script lang="ts" setup>
import BackButton from "@/shared/components/AppNavigation/BackButton/index.vue";
</script>

<template>
  <header class="navigation-header">
    <BackButton class="navigation-header__back" />
    <div id="header-left" class="navigation-header__left"></div>
    <div id="header-right" class="navigation-header__right"></div>
  </header>
</template>

<style lang="scss" scoped>
@import "index";
</style>

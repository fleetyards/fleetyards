<script lang="ts" setup>
import HomeSearch from "@/frontend/components/Home/Search/index.vue";
</script>

<template>
  <Teleport to="#header-left">
    <HomeSearch />
  </Teleport>
  <router-view />
</template>

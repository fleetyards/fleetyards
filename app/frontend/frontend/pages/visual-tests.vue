<script lang="ts">
export default {
  name: "VisualTestsPage",
};
</script>

<script lang="ts" setup>
const route = useRoute();
</script>

<template>
  <h1>Visual Tests {{ route.meta?.title }}</h1>

  <router-view />
</template>

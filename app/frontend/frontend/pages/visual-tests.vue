<template>
  <section class="container">
    <h1>Visual Tests {{ route.meta?.title }}</h1>

    <router-view />
  </section>
</template>

<script lang="ts" setup>
const route = useRoute();
</script>

<script lang="ts">
export default {
  name: "VisualTestsPage",
};
</script>

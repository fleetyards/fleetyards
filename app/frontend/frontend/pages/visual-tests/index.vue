<script lang="ts">
export default {
  name: "VisualTestsOverviewPage",
};
</script>

<script lang="ts" setup>
import { routes as subRoutes } from "./routes";

const filteredRoutes = computed(() => {
  return subRoutes.filter((route) => route.path !== "");
});
</script>

<template>
  <ul>
    <li v-for="subRoute in filteredRoutes" :key="subRoute.name">
      <router-link :to="{ name: subRoute.name }">
        {{ subRoute.meta.title }}
      </router-link>
    </li>
  </ul>
</template>

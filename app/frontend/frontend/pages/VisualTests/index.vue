<template>
  <section class="container">
    <template v-if="isSubRoute">
      <h1>Visual Tests {{ route.meta?.title }}</h1>

      <router-view />
    </template>
    <template v-else>
      <h1>Visual Tests Overview</h1>

      <ul>
        <li v-for="subRoute in subRoutes" :key="subRoute.name">
          <router-link :to="{ name: subRoute.name }">
            {{ subRoute.meta.title }}
          </router-link>
        </li>
      </ul>
    </template>
  </section>
</template>

<script lang="ts" setup>
import { routes as subRoutes } from "./routes";

const route = useRoute();

const isSubRoute = computed(() => route.name !== "visual-tests");
</script>

<script lang="ts">
export default {
  name: "VisualTestsIndexPage",
};
</script>

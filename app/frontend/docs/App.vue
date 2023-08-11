<template>
  <div>
    <AppBackground />
    <AppNavigation />
    <div class="lg:pl-72">
      <transition name="fade" mode="out-in">
        <router-view :key="route.path" class="main" />
      </transition>
    </div>
  </div>
</template>

<script lang="ts" setup>
import AppNavigation from "@/docs/components/core/AppNavigation/index.vue";
import AppBackground from "@/docs/components/core/AppBackground/index.vue";
import { useRoute } from "vue-router/composables";

const route = useRoute();
</script>

<script lang="ts">
export default {
  name: "DocsApp",
};
</script>

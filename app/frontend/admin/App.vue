<template>
  <div id="app" class="app-body container-fluid">
    <transition name="fade" mode="out-in" appear>
      <router-view />
    </transition>
    <AppModal />
  </div>
</template>

<script lang="ts" setup>
import AppModal from "@/frontend/core/components/AppModal/index.vue";
</script>

<script lang="ts">
export default {
  name: "AdminApp",
};
</script>

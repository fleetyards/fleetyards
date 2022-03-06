<template>
  <div id="app" class="app-body container-fluid">
    <transition name="fade" mode="out-in" appear>
      <router-view />
    </transition>
    <AppModal />
  </div>
</template>

<script>
import AppModal from '@/frontend/core/components/AppModal/index.vue'

export default {
  components: {
    AppModal,
  },
}
</script>

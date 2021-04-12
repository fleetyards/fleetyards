<template>
  <div id="app" class="app-body container-fluid">
    <transition name="fade" mode="out-in" appear>
      <router-view />
    </transition>
    <AppModal />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import AppModal from 'frontend/core/components/AppModal'

@Component<AdminApp>({
  components: {
    AppModal,
  },
})
export default class AdminApp extends Vue {}
</script>

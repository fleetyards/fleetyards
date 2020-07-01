<template>
  <div id="app" class="app-body container-fluid">
    <transition name="fade" mode="out-in" appear>
      <router-view />
    </transition>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'

@Component<AdminApp>({})
export default class AdminApp extends Vue {}
</script>

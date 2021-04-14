<template>
  <router-view />
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'

@Component<SettingsTwoFactor>({})
export default class SettingsTwoFactor extends Vue {}
</script>

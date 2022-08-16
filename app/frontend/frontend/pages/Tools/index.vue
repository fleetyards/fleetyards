<template>
  <router-view />
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'

@Component<Tools>({})
export default class Tools extends Vue {}
</script>

<template>
  <div class="panel-btn-group">
    <slot />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'

@Component({})
export default class BtnGroup extends Vue {}
</script>

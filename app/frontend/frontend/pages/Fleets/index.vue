<template>
  <router-view />
</template>

<script lang="ts">
import Vue from "vue";
import { Component } from "vue-property-decorator";

@Component<Fleets>({})
export default class Fleets extends Vue {}
</script>

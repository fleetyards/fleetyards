<template>
  <router-view />
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'

@Component<Fleets>({})
export default class Fleets extends Vue {
  mounted() {
    if (this.$route.name === 'fleets') {
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      this.$router.push({ name: 'home' }).catch(() => {})
    }
  }
}
</script>

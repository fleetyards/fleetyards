<template>
  <ol aria-label="breadcrumb" class="breadcrumb">
    <li class="breadcrumb-item">
      <router-link :to="{ name: 'home' }">
        {{ $t('nav.home') }}
      </router-link>
    </li>
    <li v-for="(crumb, index) in crumbs" :key="index" class="breadcrumb-item">
      <router-link :to="crumb.to">
        {{ crumb.label }}
      </router-link>
    </li>
  </ol>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Panel from 'frontend/core/components/Panel/index.vue'

@Component({
  components: {
    Panel,
  },
})
export default class BreadCrumbs extends Vue {
  @Prop({
    default() {
      return []
    },
  })
  crumbs!: Object[]
}
</script>

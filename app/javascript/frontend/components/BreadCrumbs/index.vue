<template>
  <ol
    aria-label="breadcrumb"
    class="breadcrumb"
  >
    <li class="breadcrumb-item">
      <router-link :to="{ name: 'home' }">
        {{ $t('nav.home') }}
      </router-link>
    </li>
    <li
      v-for="(crumb, index) in crumbs"
      :key="index"
      class="breadcrumb-item"
    >
      /
      <router-link :to="crumb.to">
        {{ crumb.label }}
      </router-link>
    </li>
  </ol>
</template>

<script>
export default {
  props: {
    crumbs: {
      type: Array,
      default() {
        return []
      },
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>

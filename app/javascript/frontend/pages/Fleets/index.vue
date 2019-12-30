<template>
  <router-view v-if="isSubRoute" />
  <section
    v-else
    class="container"
  >
    <div class="row">
      <div class="col-xs-12">
        <h1 class="sr-only">
          {{ $t('headlines.fleets.index') }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        Fleets
      </div>
    </div>
  </section>
</template>

<script>
export default {
  name: 'Fleets',

  computed: {
    isSubRoute() {
      return this.$route.name !== 'fleets'
    },
  },
}
</script>

<template>
  <section class="container">
    <div class="row">
      <div class="col-md-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1>{{ $t('headlines.fleets.settings.membership') }}</h1>
      </div>
    </div>
  </section>
</template>

<script>
import BreadCrumbs from 'frontend/components/BreadCrumbs'
import MetaInfo from 'frontend/mixins/MetaInfo'
import FleetsMixin from 'frontend/mixins/Fleets'

export default {
  name: 'FleetSettings',

  components: {
    BreadCrumbs,
  },

  mixins: [
    MetaInfo,
    FleetsMixin,
  ],

  props: {
    fleet: {
      type: Object,
      required: true,
    },
  },

  computed: {
    metaTitle() {
      if (!this.fleet) {
        return null
      }

      return this.$t('title.fleets.settings', { fleet: this.fleet.name })
    },

    crumbs() {
      if (!this.fleet) {
        return []
      }

      return [{
        to: {
          name: 'fleet',
          params: {
            slug: this.fleet.slug,
          },
        },
        label: this.fleet.name,
      }]
    },
  },
}
</script>

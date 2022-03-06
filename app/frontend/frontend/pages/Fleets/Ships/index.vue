<template>
  <section class="container fleet-detail">
    <div v-if="fleet" class="row">
      <div class="col-12 col-lg-8">
        <h1 class="heading">
          <Avatar
            v-if="fleet.logo"
            :avatar="fleet.logo"
            :transparent="!!fleet.logo"
            icon="fad fa-image"
          />
          {{ fleet.name }} ({{ fleet.fid }})
        </h1>
      </div>
      <div
        class="col-12 col-lg-4 d-flex justify-content-end align-items-center"
      >
        <div v-if="!mobile" class="page-actions">
          <Btn
            :inline="true"
            data-test="fleetchart-link"
            @click.native="toggleFleetchart"
          >
            <i class="fad fa-starship" />
            {{ $t('labels.fleetchart') }}
          </Btn>

          <ShareBtn
            v-if="fleet.myFleet && fleet.publicFleet"
            :url="shareUrl"
            :title="metaTitle"
            :inline="true"
          />
        </div>
      </div>
    </div>

    <br />

    <template v-if="fleet">
      <ShipsList
        v-if="fleet.myFleet"
        :fleet="fleet"
        :share-url="shareUrl"
        :meta-title="metaTitle"
      />
      <PublicShipsList v-else-if="fleet.publicFleet" :fleet="fleet" />
    </template>
  </section>
</template>

<script>
import { mapGetters } from 'vuex'
import Avatar from '@/frontend/core/components/Avatar/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import ShareBtn from '@/frontend/components/ShareBtn/index.vue'
import ShipsList from '@/frontend/components/Fleets/ShipsList/index.vue'
import PublicShipsList from '@/frontend/components/Fleets/PublicShipsList/index.vue'
import MetaInfo from '@/frontend/mixins/MetaInfo'
import fleetsCollection from '@/frontend/api/collections/Fleets'
import { publicFleetShipsRouteGuard } from '@/frontend/utils/RouteGuards/Fleets'

export default {
  name: 'FleetShips',
  components: {
    Avatar,
    Btn,
    PublicShipsList,
    ShareBtn,
    ShipsList,
  },

  mixins: [MetaInfo],

  beforeRouteEnter: publicFleetShipsRouteGuard,

  computed: {
    ...mapGetters(['mobile']),

    fleet() {
      return fleetsCollection.record
    },
    metaTitle() {
      if (!this.fleet) {
        return null
      }

      return this.fleet.name
    },

    shareUrl() {
      if (!this.fleet) {
        return ''
      }
      const host = `${window.location.protocol}//${window.location.host}`

      return `${host}/fleets/${this.fleet.slug}/ships`
    },
  },

  watch: {
    $route() {
      this.fetch()
    },
  },

  mounted() {
    this.fetch()
  },

  methods: {
    async fetch() {
      await fleetsCollection.findBySlug(this.$route.params.slug)
    },

    toggleFleetchart() {
      if (this.fleet.myFleet) {
        this.$store.dispatch('fleet/toggleFleetchart')
      } else {
        this.$store.dispatch('publicFleet/toggleFleetchart')
      }
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index.scss';
</style>

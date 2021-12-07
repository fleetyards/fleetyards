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
            :to="{
              name: 'fleet-fleetchart',
              params: { slug: fleet.slug },
            }"
            :inline="true"
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
        :copy-public-url="copyShareUrl"
      />
      <PublicShipsList v-else-if="fleet.publicFleet" :fleet="fleet" />
    </template>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import Avatar from 'frontend/core/components/Avatar'
import Btn from 'frontend/core/components/Btn'
import ShareBtn from 'frontend/components/ShareBtn'
import ShipsList from 'frontend/components/Fleets/ShipsList'
import PublicShipsList from 'frontend/components/Fleets/PublicShipsList'
import MetaInfo from 'frontend/mixins/MetaInfo'
import HangarItemsMixin from 'frontend/mixins/HangarItems'
import { publicFleetShipsRouteGuard } from 'frontend/utils/RouteGuards/Fleets'
import fleetsCollection from 'frontend/api/collections/Fleets'

@Component<FleetShips>({
  beforeRouteEnter: publicFleetShipsRouteGuard,
  components: {
    Avatar,
    Btn,
    ShareBtn,
    ShipsList,
    PublicShipsList,
  },
  mixins: [MetaInfo, HangarItemsMixin],
})
export default class FleetShips extends Vue {
  @Getter('mobile') mobile

  get fleet() {
    return fleetsCollection.record
  }

  get metaTitle() {
    if (!this.fleet) {
      return null
    }

    return this.fleet.name
  }

  get shareUrl() {
    if (!this.fleet) {
      return ''
    }
    const host = `${window.location.protocol}//${window.location.host}`

    return `${host}/fleets/${this.fleet.slug}/ships`
  }

  @Watch('$route')
  onRouteChange() {
    this.fetch()
  }

  mounted() {
    this.fetch()
  }

  async fetch() {
    await fleetsCollection.findBySlug(this.$route.params.slug)
  }
}
</script>

<style lang="scss" scoped>
.heading {
  display: flex;
  align-items: center;
  justify-content: flex-start;

  .avatar {
    margin-right: 20px;
  }
}
</style>

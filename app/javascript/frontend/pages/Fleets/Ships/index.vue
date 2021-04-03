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

          <Btn
            v-if="fleet.publicFleet"
            v-tooltip="$t('actions.copyPublicUrl')"
            :inline="true"
            @click.native="copyPublicUrl"
          >
            <i class="fad fa-share-square" />
          </Btn>
        </div>
      </div>
    </div>

    <br />

    <template v-if="fleet">
      <ShipsList
        v-if="fleet.myFleet"
        :fleet="fleet"
        :copy-public-url="copyPublicUrl"
      />
      <PublicShipsList v-else :fleet="fleet" />
    </template>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import Avatar from 'frontend/core/components/Avatar'
import copyText from 'frontend/utils/CopyText'
import Btn from 'frontend/core/components/Btn'
import ShipsList from 'frontend/components/Fleets/ShipsList'
import PublicShipsList from 'frontend/components/Fleets/PublicShipsList'
import MetaInfo from 'frontend/mixins/MetaInfo'
import HangarItemsMixin from 'frontend/mixins/HangarItems'
import { publicFleetShipsRouteGuard } from 'frontend/utils/RouteGuards'
import fleetsCollection from 'frontend/api/collections/Fleets'
import { displayAlert, displaySuccess } from 'frontend/lib/Noty'

@Component<FleetShips>({
  beforeRouteEnter: publicFleetShipsRouteGuard,
  components: {
    Avatar,
    Btn,
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

  get publicUrl() {
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

  copyPublicUrl(_event) {
    copyText(this.publicUrl).then(
      () => {
        displaySuccess({
          text: this.$t('messages.copyPublicUrl.success', {
            publicUrl: this.publicUrl,
          }),
        })
      },
      () => {
        displayAlert({
          text: this.$t('messages.copyPublicUrl.failure'),
        })
      },
    )
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

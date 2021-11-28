<template>
  <section class="container stats hangar hangar-public">
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <BreadCrumbs
              :crumbs="[
                {
                  to: {
                    name: 'hangar-public',
                    params: { slug: username },
                  },
                  label: $t('headlines.hangar.public', {
                    user: usernamePlural,
                  }),
                },
              ]"
            />
            <h1>
              <Avatar :avatar="user.avatar" />
              <span>
                {{
                  $t('headlines.hangar.publicStats', { user: usernamePlural })
                }}
              </span>
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-md-3">
            <Panel variant="primary">
              <div class="panel-box">
                <div class="panel-box-icon">
                  <i class="fad fa-rocket fa-4x" />
                </div>
                <div class="panel-box-text">
                  {{ totalCount }}
                  <div class="panel-box-text-info">
                    {{ $t('labels.stats.quickStats.totalShips') }}
                  </div>
                </div>
              </div>
            </Panel>
          </div>
          <div class="col-12 col-md-3">
            <Panel variant="primary">
              <div class="panel-box">
                <div class="panel-box-icon">
                  <i class="fad fa-user fa-4x" />
                </div>
                <div class="panel-box-text">
                  {{ minCrew }}
                  <div class="panel-box-text-info">
                    {{ $t('labels.hangarMetrics.totalMinCrew') }}
                  </div>
                </div>
              </div>
            </Panel>
          </div>
          <div class="col-12 col-md-3">
            <Panel variant="primary">
              <div class="panel-box">
                <div class="panel-box-icon">
                  <i class="fad fa-users fa-4x" />
                </div>
                <div class="panel-box-text">
                  {{ maxCrew }}
                  <div class="panel-box-text-info">
                    {{ $t('labels.hangarMetrics.totalMaxCrew') }}
                  </div>
                </div>
              </div>
            </Panel>
          </div>
          <div class="col-12 col-md-3">
            <Panel variant="primary">
              <div class="panel-box">
                <div class="panel-box-icon">
                  <i class="fad fa-box-open fa-4x" />
                </div>
                <div class="panel-box-text">
                  {{ totalCargo }}
                  <div class="panel-box-text-info">
                    {{ $t('labels.hangarMetrics.totalCargo') }}
                  </div>
                </div>
              </div>
            </Panel>
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-lg-6">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ $t('labels.stats.modelsByClassification') }}
                </h2>
              </div>
              <Chart
                key="models-by-classification"
                :load-data="loadModelsByClassification"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
          <div class="col-12 col-lg-6">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ $t('labels.stats.modelsBySize') }}
                </h2>
              </div>
              <Chart
                key="models-by-size"
                :load-data="loadModelsBySize"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-lg-4">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ $t('labels.stats.modelsByProductionStatus') }}
                </h2>
              </div>
              <Chart
                key="models-by-production-status"
                :load-data="loadModelsByProductionStatus"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
          <div class="col-12 col-lg-6">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ $t('labels.stats.modelsByManufacturer') }}
                </h2>
              </div>
              <Chart
                key="models-by-manufacturer"
                :load-data="loadModelsByManufacturer"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Chart from 'frontend/core/components/Chart'
import Panel from 'frontend/core/components/Panel'
import BreadCrumbs from 'frontend/core/components/BreadCrumbs'
import Avatar from 'frontend/core/components/Avatar'
import publicUserCollection from 'frontend/api/collections/PublicUser'
import publicHangarStatsCollection from 'frontend/api/collections/PublicHangarStats'
import { publicHangarStatsRouteGuard } from 'frontend/utils/RouteGuards/Hangar'

@Component<PublicHangarStats>({
  beforeRouteEnter: publicHangarStatsRouteGuard,
  components: {
    Chart,
    Avatar,
    Panel,
    BreadCrumbs,
  },
  mixins: [MetaInfo],
})
export default class PublicHangarStats extends Vue {
  get metaTitle() {
    return this.$t('title.hangar.publicStats', { user: this.usernamePlural })
  }

  get username() {
    return this.$route.params.username
  }

  get user() {
    return this.userCollection.record
  }

  get filters() {
    return {
      username: this.username,
      page: this.$route.query.page,
    }
  }

  get usernamePlural() {
    if (
      this.userTitle.endsWith('s') ||
      this.userTitle.endsWith('x') ||
      this.userTitle.endsWith('z')
    ) {
      return this.userTitle
    }

    return `${this.userTitle}'s`
  }

  get userTitle() {
    return this.username[0].toUpperCase() + this.username.slice(1)
  }

  get totalCount() {
    if (!this.quickStats) {
      return 0
    }

    return this.quickStats.total
  }

  get minCrew() {
    if (!this.quickStats) {
      return this.$toNumber(0, 'people')
    }

    return this.$toNumber(this.quickStats.metrics.totalMinCrew, 'people')
  }

  get maxCrew() {
    if (!this.quickStats) {
      return this.$toNumber(0, 'people')
    }

    return this.$toNumber(this.quickStats.metrics.totalMaxCrew, 'people')
  }

  get totalCargo() {
    if (!this.quickStats) {
      return this.$toNumber(0, 'cargo')
    }

    return this.$toNumber(this.quickStats.metrics.totalCargo, 'cargo')
  }

  userCollection: PublicUserCollection = publicUserCollection

  collection: PublicHangarStatsCollection = publicHangarStatsCollection

  quickStats = null

  @Watch('$route')
  onRouteChange() {
    this.fetch()
  }

  created() {
    this.fetch()
  }

  async fetch() {
    this.quickStats = await this.collection.quickStats(this.username)
  }

  async loadModelsByClassification() {
    return this.collection.modelsByClassification(this.username)
  }

  async loadModelsBySize() {
    return this.collection.modelsBySize(this.username)
  }

  async loadModelsByManufacturer() {
    return this.collection.modelsByManufacturer(this.username)
  }

  async loadModelsByProductionStatus() {
    return this.collection.modelsByProductionStatus(this.username)
  }
}
</script>

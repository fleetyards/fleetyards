<template>
  <section class="container roadmap">
    <div class="row">
      <div class="col-xs-12">
        <h1 class="sr-only">
          {{ $t('headlines.roadmap') }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <div class="page-actions">
          <Btn :to="{ name: 'roadmap', exact: true }">
            {{ $t('labels.roadmap.shipRoadmap') }}
          </Btn>
          <Btn :to="{ name: 'roadmap-releases' }">
            {{ $t('labels.roadmap.releases') }}
          </Btn>
          <Btn href="https://robertsspaceindustries.com/roadmap">
            {{ $t('labels.rsiRoadmap') }}
          </Btn>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <transition-group
          name="fade-list"
          class="flex-row"
          tag="div"
          appear
        >
          <div
            v-for="(items, release) in groupedByRelease"
            :key="`releases-${release}`"
            class="col-xs-12 fade-list-item release"
          >
            <h2>
              <span class="title">{{ release }}</span>
              <span class="released-label">
                ({{ items[0].releaseDescription }})
              </span>
              <small>{{ $t('labels.roadmap.ships', { count: items.length }) }}</small>
            </h2>

            <div class="flex-row">
              <div
                v-for="item in items"
                :key="item.id"
                class="col-xs-12 col-sm-6 col-xxlg-4 fade-list-item"
              >
                <RoadmapItem :item="item" />
              </div>
            </div>
          </div>
        </transition-group>
        <EmptyBox v-if="emptyBoxVisible" />
        <Loader
          :loading="loading"
          fixed
        />
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import Btn from 'frontend/components/Btn'
import RoadmapItem from 'frontend/partials/Roadmap/RoadmapItem'
import EmptyBox from 'frontend/partials/EmptyBox'
import { subDays, format } from 'date-fns'

export default {
  name: 'RoadmapChanges',

  components: {
    Loader,
    EmptyBox,
    Btn,
    RoadmapItem,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    return {
      loading: true,
      roadmapChanges: [],
      roadmapChannel: null,
    }
  },

  computed: {
    emptyBoxVisible() {
      return !this.loading && this.roadmapChanges.length === 0
    },

    groupedByRelease() {
      return this.roadmapChanges.reduce((rv, x) => {
        const value = JSON.parse(JSON.stringify(rv))

        value[x.release] = rv[x.release] || []
        value[x.release].push(x)

        return value
      }, {})
    },
  },

  mounted() {
    this.fetch()
    this.setupUpdates()
  },

  beforeDestroy() {
    if (this.roadmapChannel) {
      this.roadmapChannel.unsubscribe()
    }
  },

  methods: {
    setupUpdates() {
      if (this.roadmapChannel) {
        this.roadmapChannel.unsubscribe()
      }

      this.roadmapChannel = this.$cable.subscriptions.create({
        channel: 'RoadmapChannel',
      }, {
        received: this.fetch,
      })
    },

    async fetch() {
      this.loading = true
      const response = await this.$api.get('roadmap', {
        q: {
          lastUpdatedAtGteq: format(subDays(new Date(), 6), 'YYYY-MM-DD'),
        },
      })

      this.loading = false

      if (!response.error) {
        this.roadmapChanges = response.data.filter((item) => item.lastVersion)
      }
    },
  },
}
</script>

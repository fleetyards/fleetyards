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
          class="row"
          tag="div"
          appear
        >
          <div
            v-for="(items, release) in groupedByRelease"
            :key="`releases-${release}`"
            class="col-xs-12 fade-list-item release"
          >
            <h2
              :class="{
                open: visible.includes(release),
              }"
              class="toggleable"
              @click="toggle(release)"
            >
              <span class="title">{{ release }}</span>
              <span class="released-label">
                ({{ items[0].releaseDescription }})
              </span>
              <small>{{ $t('labels.roadmap.ships', { count: items.length }) }}</small>
              <i class="fa fa-chevron-right" />
            </h2>

            <b-collapse
              :id="`${release}-cards`"
              :visible="visible.includes(release)"
            >
              <div class="flex-row">
                <div
                  v-for="item in items"
                  :key="item.id"
                  class="col-xs-12 col-sm-6 col-xxlg-4 fade-list-item"
                >
                  <RoadmapItem
                    :item="item"
                    slim
                  />
                </div>
              </div>
            </b-collapse>
          </div>
        </transition-group>
        <EmptyBox :visible="emptyBoxVisible" />
        <Loader
          :loading="loading"
          fixed
        />
        <div class="row">
          <div class="col-xs-12 fade-list-item release">
            <h2
              :class="{
                open: visible.includes('unscheduled'),
              }"
              class="toggleable"
              @click="toggle('unscheduled')"
            >
              <span class="title">
                {{ $t('labels.roadmap.unscheduled') }}
              </span>
              <small>{{ $t('labels.roadmap.ships', { count: unscheduledModels.length }) }}</small>
              <i class="fa fa-chevron-right" />
            </h2>
            <b-collapse
              id="unscheduled-cards"
              :visible="visible.includes('unscheduled')"
            >
              <div class="flex-row">
                <div
                  v-for="model in unscheduledModels"
                  :key="model.slug"
                  class="col-xs-12 col-sm-6 col-xxlg-4 fade-list-item"
                >
                  <RoadmapItem :item="model" />
                </div>
              </div>
            </b-collapse>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import RoadmapItem from 'frontend/partials/Roadmap/RoadmapItem'
import EmptyBox from 'frontend/partials/EmptyBox'
import Btn from 'frontend/components/Btn'

export default {
  name: 'Roadmap',

  components: {
    Loader,
    EmptyBox,
    RoadmapItem,
    Btn,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    return {
      loading: true,
      onlyReleased: true,
      roadmapItems: [],
      visible: [],
      unscheduledModels: [],
      roadmapChannel: null,
    }
  },

  computed: {
    releasedToggleLabel() {
      if (this.onlyReleased) {
        return this.$t('actions.showReleased')
      }
      return this.$t('actions.hideReleased')
    },

    emptyBoxVisible() {
      return !this.loading && this.roadmapItems.length === 0
    },

    filteredItems() {
      if (this.onlyReleased) {
        return this.roadmapItems.filter((item) => !item.released)
      }
      return this.roadmapItems
    },

    groupedByRelease() {
      return this.filteredItems.reduce((rv, x) => {
        const value = JSON.parse(JSON.stringify(rv))

        value[x.release] = rv[x.release] || []
        value[x.release].push(x)

        return value
      }, {})
    },

    otherModels() {
      return this.models
    },

    modelsOnRoadmap() {
      return this.roadmapItems.filter((item) => item.model)
        .map((item) => item.model.id)
        .filter((item) => item)
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

    toggleReleased() {
      this.onlyReleased = !this.onlyReleased
    },

    toggle(release) {
      if (this.visible.includes(release)) {
        const index = this.visible.indexOf(release)
        this.visible.splice(index, 1)
        return null
      }
      return this.visible.push(release)
    },

    openReleased() {
      Object.keys(this.groupedByRelease).forEach((release) => {
        const items = this.groupedByRelease[release]
        if (items.length && !items[0].released) {
          this.visible.push(release)
        }
      })
    },

    async fetch() {
      this.loading = true
      const response = await this.$api.get('roadmap', {
        q: {
          rsiCategoryIdIn: [6],
          activeEq: true,
        },
      })
      this.loading = false

      if (!response.error) {
        this.roadmapItems = response.data
        await this.fetchModels()
        this.openReleased()
      }
    },

    async fetchModels() {
      const response = await this.$api.get('models/unscheduled')
      if (!response.error) {
        this.unscheduledModels = response.data
      }
    },
  },
}
</script>

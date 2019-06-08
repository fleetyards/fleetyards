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
          <Btn :to="{ name: 'roadmap-changes' }">
            {{ $t('labels.roadmap.changes') }}
          </Btn>
          <Btn href="https://robertsspaceindustries.com/roadmap">
            {{ $t('labels.rsiRoadmap') }}
          </Btn>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <div class="text-center">
          <a
            class="show-released"
            @click="toggleReleased"
          >
            - {{ releasedToggleLabel }} -
          </a>
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
              <b-progress :max="tasks(items)">
                <div
                  v-tooltip="progressLabel(items)"
                  class="progress-label"
                >
                  {{ completedPercent(items) }} %
                  <template v-if="showInprogress(items)">
                    {{ $t('labels.roadmap.inprogress', {
                      count: inprogress(items),
                    }) }}
                  </template>
                </div>
                <b-progress-bar
                  v-if="completed(items) !== 0"
                  :value="completed(items)"
                  :class="{
                    completed: completed(items) === tasks(items)
                  }"
                />
                <b-progress-bar
                  v-if="showInprogress(items)"
                  :value="inprogress(items)"
                  class="active"
                />
              </b-progress>

              <div class="flex-row">
                <div
                  v-for="item in items"
                  :key="item.id"
                  class="col-xs-12 col-xxlg-4 fade-list-item"
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
import RoadmapItem from 'frontend/partials/Roadmap/RoadmapItem'
import Btn from 'frontend/components/Btn'
import EmptyBox from 'frontend/partials/EmptyBox'

export default {
  components: {
    Loader,
    EmptyBox,
    RoadmapItem,
    Btn,
  },
  mixins: [MetaInfo],
  data() {
    return {
      loading: true,
      onlyReleased: true,
      roadmapItems: [],
      visible: [],
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
        return this.roadmapItems.filter(item => !item.released)
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
      return this.roadmapItems.filter(item => item.model)
        .map(item => item.model.id)
        .filter(item => item)
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
    showInprogress(items) {
      return this.inprogress(items) !== 0 && this.completed(items) !== this.tasks(items)
    },
    tasks(items) {
      return items.map(item => Math.max(0, item.tasks))
        .reduce((ac, count) => ac + count, 0)
    },
    inprogress(items) {
      return items.map(item => Math.max(0, item.inprogress - item.completed))
        .reduce((ac, count) => ac + count, 0)
    },
    completed(items) {
      return items.map(item => Math.max(0, item.completed))
        .reduce((ac, count) => ac + count, 0)
    },
    progressLabel(items) {
      return `${this.completed(items)} ${this.$t('labels.roadmap.tasks', { count: this.tasks(items) })}`
    },
    completedPercent(items) {
      if (!this.tasks(items)) {
        return '?'
      }
      return Math.round(100 * this.completed(items) / this.tasks(items))
    },
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
      const response = await this.$api.get('roadmap')
      this.loading = false
      if (!response.error) {
        this.roadmapItems = response.data
        this.openReleased()
      }
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.$t('title.roadmap.releases'),
    })
  },
}
</script>

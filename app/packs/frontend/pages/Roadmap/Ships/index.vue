<template>
  <section class="container roadmap">
    <div class="row">
      <div class="col-12">
        <h1 class="sr-only">
          {{ $t('headlines.roadmap') }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <div class="page-actions page-actions-right">
          <Btn
            :active="!compact"
            :aria-label="toggleCompactTooltip"
            @click.native="toggleCompact"
          >
            {{ toggleCompactTooltip }}
          </Btn>
          <Btn href="https://robertsspaceindustries.com/roadmap">
            {{ $t('labels.rsiRoadmap') }}
          </Btn>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="(items, release) in groupedByRelease"
            :key="`releases-${release}`"
            class="col-12 fade-list-item release"
          >
            <h2
              :class="{
                open: visible.includes(release),
              }"
              class="toggleable"
              @click="toggle(release)"
            >
              <span class="title">{{ release }}</span>
              <span v-if="items[0].releaseDescription" class="released-label">
                ({{ items[0].releaseDescription }})
              </span>
              <small class="text-muted">
                {{ $t('labels.roadmap.ships', { count: items.length }) }}
              </small>
              <i class="fa fa-chevron-right" />
            </h2>

            <BCollapse
              :id="`${release}-cards`"
              :visible="visible.includes(release)"
            >
              <div class="row">
                <div
                  v-for="item in items"
                  :key="item.id"
                  class="col-12 col-lg-6 col-xl-4 col-xxl-2dot4 fade-list-item"
                >
                  <RoadmapItem :item="item" :compact="compact" />
                </div>
              </div>
            </BCollapse>
          </div>
        </transition-group>
        <EmptyBox :visible="emptyBoxVisible" />
        <Loader :loading="loading" fixed />
        <div class="row">
          <div class="col-12 fade-list-item release">
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
              <small class="text-muted">
                {{
                  $t('labels.roadmap.ships', {
                    count: unscheduledModels.length,
                  })
                }}
              </small>
              <i class="fa fa-chevron-right" />
            </h2>
            <BCollapse
              id="unscheduled-cards"
              :visible="visible.includes('unscheduled')"
            >
              <div class="row">
                <div
                  v-for="model in unscheduledModels"
                  :key="model.slug"
                  class="col-12 col-lg-6 col-xl-4 col-xxl-2dot4 fade-list-item"
                >
                  <RoadmapItem
                    :item="model"
                    :compact="compact"
                    :active="true"
                    :show-progress="false"
                  />
                </div>
              </div>
            </BCollapse>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { BCollapse } from 'bootstrap-vue'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/core/components/Loader'
import RoadmapItem from 'frontend/components/Roadmap/RoadmapItem'
import EmptyBox from 'frontend/core/components/EmptyBox'
import Btn from 'frontend/core/components/Btn'

@Component<ShipsRoadmap>({
  components: {
    BCollapse,
    Loader,
    EmptyBox,
    RoadmapItem,
    Btn,
  },

  mixins: [MetaInfo],
})
export default class ShipsRoadmap extends Vue {
  loading: boolean = true

  onlyReleased: boolean = true

  compact: boolean = true

  roadmapItems = []

  visible = []

  unscheduledModels = []

  roadmapChannel = null

  get toggleCompactTooltip() {
    if (this.compact) {
      return this.$t('actions.showDetails')
    }

    return this.$t('actions.hideDetails')
  }

  get releasedToggleLabel() {
    if (this.onlyReleased) {
      return this.$t('actions.showReleased')
    }
    return this.$t('actions.hideReleased')
  }

  get emptyBoxVisible() {
    return !this.loading && this.roadmapItems.length === 0
  }

  get filteredItems() {
    const items = this.roadmapItems.filter((item) => item.model)

    if (this.onlyReleased) {
      return items.filter((item) => !item.released)
    }

    return items
  }

  get groupedByRelease() {
    return this.filteredItems.reduce((rv, x) => {
      const value = { ...rv }

      value[x.release] = rv[x.release] || []
      value[x.release].push(x)

      return value
    }, {})
  }

  get otherModels() {
    return this.models
  }

  get modelsOnRoadmap() {
    return this.roadmapItems
      .filter((item) => item.model)
      .map((item) => item.model.id)
      .filter((item) => item)
  }

  mounted() {
    this.fetch()
    this.setupUpdates()
  }

  beforeDestroy() {
    if (this.roadmapChannel) {
      this.roadmapChannel.unsubscribe()
    }
  }

  setupUpdates() {
    if (this.roadmapChannel) {
      this.roadmapChannel.unsubscribe()
    }

    this.roadmapChannel = this.$cable.consumer.subscriptions.create(
      {
        channel: 'RoadmapChannel',
      },
      {
        received: this.fetch,
      }
    )
  }

  toggleReleased() {
    this.onlyReleased = !this.onlyReleased
  }

  toggleCompact() {
    this.compact = !this.compact
  }

  toggle(release) {
    if (this.visible.includes(release)) {
      const index = this.visible.indexOf(release)
      this.visible.splice(index, 1)
      return null
    }
    return this.visible.push(release)
  }

  openReleased() {
    Object.keys(this.groupedByRelease).forEach((release) => {
      const items = this.groupedByRelease[release]
      if (items.length && !items[0].released) {
        this.visible.push(release)
      }
    })
  }

  async fetch() {
    this.loading = true
    const response = await this.$api.get('roadmap?ships=1', {
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
  }

  async fetchModels() {
    const response = await this.$api.get('models/unscheduled')
    if (!response.error) {
      this.unscheduledModels = response.data
    }
  }
}
</script>

<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1 class="sr-only">
          {{ t('headlines.roadmap') }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12">
        <div class="page-actions">
          <ExternalLink url="https://robertsspaceindustries.com/roadmap">
            {{ t('labels.rsiRoadmap') }}
          </ExternalLink>
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
            :key="release"
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
              <small>{{ t('labels.roadmap.ships', { count: items.length }) }}</small>
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
                  <Panel>
                    <div class="roadmap-item">
                      <div
                        :style="{
                          'background-image': `url(https://robertsspaceindustries.com${item.image})`
                        }"
                        class="item-image"
                      >
                        <div
                          v-if="recentlyUpdated(item)"
                          v-tooltip="t('labels.roadmap.recentlyUpdated')"
                          class="roadmap-item-updated"
                        />
                      </div>
                      <div class="item-body">
                        <h3>
                          <router-link
                            v-if="item.model"
                            :to="{
                              name: 'model',
                              params: {
                                slug: item.model.slug
                              }
                            }"
                          >
                            {{ item.name }}
                          </router-link>
                          <template v-else>
                            {{ item.name }}
                          </template>
                          <i
                            v-tooltip="t('labels.roadmap.lastUpdate', { date: l(item.updatedAt) })"
                            class="fal fa-info-circle"
                          />
                        </h3>
                        <p>{{ item.body }}</p>
                        <b-progress :max="item.tasks">
                          <b-progress-bar
                            v-if="item.completed !== 0"
                            :value="item.completed"
                            :class="{
                              completed: item.completed === item.tasks
                            }"
                          >
                            {{ item.completed }} / {{ item.tasks }}
                          </b-progress-bar>
                          <div class="progress-max">
                            {{ t('labels.roadmap.tasks', { count: item.tasks }) }}
                          </div>
                        </b-progress>
                      </div>
                    </div>
                  </Panel>
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
        <div class="row">
          <div class="col-xs-12 fade-list-item release">
            <h2
              :class="{
                open: visible.includes('unscheduled'),
              }"
              @click="toggle('unscheduled')"
            >
              <span class="title">
                {{ t('labels.roadmap.unscheduled') }}
              </span>
              <small>{{ t('labels.roadmap.ships', { count: unscheduledModels.length }) }}</small>
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
                  <Panel>
                    <div class="roadmap-item">
                      <div
                        :style="{
                          'background-image': `url(${model.storeImage})`
                        }"
                        class="item-image"
                      />
                      <div class="item-body">
                        <h3>
                          <router-link
                            :to="{
                              name: 'model',
                              params: {
                                slug: model.slug
                              }
                            }"
                          >
                            {{ model.name }}
                          </router-link>
                        </h3>
                        <p>{{ model.description }}</p>
                        <b-progress>
                          <div class="progress-max">
                            {{ t('labels.roadmap.tasks', { count: '?' }) }}
                          </div>
                        </b-progress>
                      </div>
                    </div>
                  </Panel>
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
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import Panel from 'frontend/components/Panel'
import ExternalLink from 'frontend/components/ExternalLink'
import EmptyBox from 'frontend/partials/EmptyBox'
import { isBefore, addHours } from 'date-fns'

export default {
  components: {
    Loader,
    EmptyBox,
    Panel,
    ExternalLink,
  },
  mixins: [I18n, MetaInfo],
  data() {
    return {
      loading: true,
      onlyReleased: true,
      roadmapItems: [],
      visible: [],
      unscheduledModels: [],
    }
  },
  computed: {
    releasedToggleLabel() {
      if (this.onlyReleased) {
        return this.t('actions.showReleased')
      }
      return this.t('actions.hideReleased')
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
  watch: {
    $route() {
      this.fetch()
    },
  },
  created() {
    this.fetch()
  },
  methods: {
    recentlyUpdated(item) {
      return isBefore(new Date(), addHours(new Date(item.updatedAt), 24))
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
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.roadmap'),
    })
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>

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
      <div class="col-xs-12 col-md-6">
        <FilterGroup
          v-model="selectedWeek"
          :label="$t('labels.roadmap.selectWeek')"
          name="query"
          :options="options"
          label-attr="label"
          :nullable="false"
          @input="fetch"
        />
      </div>
      <div class="col-xs-12 col-md-6">
        <div class="page-actions">
          <Btn href="https://robertsspaceindustries.com/roadmap">
            {{ $t('labels.rsiRoadmap') }}
          </Btn>
        </div>
      </div>
    </div>
    <hr class="dark">
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
              <small>{{ $t('labels.roadmap.stories', { count: items.length }) }}</small>
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
        <EmptyBox :visible="emptyBoxVisible" />
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
import Btn from 'frontend/components/Btn'
import Loader from 'frontend/components/Loader'
import FilterGroup from 'frontend/components/Form/FilterGroup'
import RoadmapItem from 'frontend/partials/Roadmap/RoadmapItem'
import EmptyBox from 'frontend/partials/EmptyBox'

export default {
  name: 'RoadmapChanges',

  components: {
    Btn,
    Loader,
    FilterGroup,
    EmptyBox,
    RoadmapItem,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    return {
      loading: true,
      roadmapChanges: [],
      options: [],
      roadmapChannel: null,
      selectedWeek: 0,
    }
  },

  computed: {
    emptyBoxVisible() {
      return !this.loading && this.roadmapChanges.length === 0
    },

    query() {
      if (!this.options.length) {
        return null
      }

      return this.options[this.selectedWeek].query
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

  async mounted() {
    await this.fetchOptions()
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

    async fetchOptions() {
      const response = await this.$api.get('roadmap/weeks')

      if (!response.error) {
        this.options = response.data
      }
    },

    async fetch() {
      if (!this.query) {
        return
      }

      this.loading = true
      const response = await this.$api.get('roadmap', {
        q: this.query,
      })

      this.loading = false

      if (!response.error) {
        this.roadmapChanges = response.data.filter((item) => item.lastVersion)
      }
    },
  },
}
</script>

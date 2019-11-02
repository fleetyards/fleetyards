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
        <Btn
          v-for="week in weekOptions"
          :key="week"
          :active="changesWeek === week"
          @click.native="setWeek(week)"
        >
          {{ changesQuery[week].label }}
        </Btn>
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
import Loader from 'frontend/components/Loader'
import Btn from 'frontend/components/Btn'
import RoadmapItem from 'frontend/partials/Roadmap/RoadmapItem'
import EmptyBox from 'frontend/partials/EmptyBox'
import { subDays, format, endOfWeek } from 'date-fns'

export default {
  name: 'RoadmapChanges',

  components: {
    Loader,
    Btn,
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
      roadmapChannel: null,
      changesWeek: 'current',
      weekOptions: [
        'current', 'lastWeek', 'twoWeeksAgo', 'threeWeeksAgo', 'fourWeeksAgo', 'fiveWeeksAgo',
      ],
    }
  },

  computed: {
    nextRoadmapUpdate() {
      return endOfWeek(new Date(), { weekStartsOn: 6 })
    },

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

    changesQuery() {
      return {
        current: {
          lastUpdatedAtGteq: format(subDays(this.nextRoadmapUpdate, 7), 'yyyy-MM-dd'),
          label: `${format(subDays(this.nextRoadmapUpdate, 7), 'yyyy-MM-dd')} - ${format(subDays(this.nextRoadmapUpdate, 13), 'yyyy-MM-dd')}`,
        },
        lastWeek: {
          lastUpdatedAtGteq: format(subDays(this.nextRoadmapUpdate, 14), 'yyyy-MM-dd'),
          lastUpdatedAtLt: format(subDays(this.nextRoadmapUpdate, 7), 'yyyy-MM-dd'),
          label: `${format(subDays(this.nextRoadmapUpdate, 14), 'yyyy-MM-dd')} - ${format(subDays(this.nextRoadmapUpdate, 20), 'yyyy-MM-dd')}`,
        },
        twoWeeksAgo: {
          lastUpdatedAtGteq: format(subDays(this.nextRoadmapUpdate, 21), 'yyyy-MM-dd'),
          lastUpdatedAtLt: format(subDays(this.nextRoadmapUpdate, 14), 'yyyy-MM-dd'),
          label: `${format(subDays(this.nextRoadmapUpdate, 21), 'yyyy-MM-dd')} - ${format(subDays(this.nextRoadmapUpdate, 27), 'yyyy-MM-dd')}`,
        },
        threeWeeksAgo: {
          lastUpdatedAtGteq: format(subDays(this.nextRoadmapUpdate, 28), 'yyyy-MM-dd'),
          lastUpdatedAtLt: format(subDays(this.nextRoadmapUpdate, 21), 'yyyy-MM-dd'),
          label: `${format(subDays(this.nextRoadmapUpdate, 28), 'yyyy-MM-dd')} - ${format(subDays(this.nextRoadmapUpdate, 34), 'yyyy-MM-dd')}`,
        },
        fourWeeksAgo: {
          lastUpdatedAtGteq: format(subDays(this.nextRoadmapUpdate, 35), 'yyyy-MM-dd'),
          lastUpdatedAtLt: format(subDays(this.nextRoadmapUpdate, 28), 'yyyy-MM-dd'),
          label: `${format(subDays(this.nextRoadmapUpdate, 35), 'yyyy-MM-dd')} - ${format(subDays(this.nextRoadmapUpdate, 41), 'yyyy-MM-dd')}`,
        },
        fiveWeeksAgo: {
          lastUpdatedAtGteq: format(subDays(this.nextRoadmapUpdate, 42), 'yyyy-MM-dd'),
          lastUpdatedAtLt: format(subDays(this.nextRoadmapUpdate, 35), 'yyyy-MM-dd'),
          label: `${format(subDays(this.nextRoadmapUpdate, 42), 'yyyy-MM-dd')} - ${format(subDays(this.nextRoadmapUpdate, 48), 'yyyy-MM-dd')}`,
        },
      }
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
    setWeek(week) {
      this.changesWeek = week
      this.fetch()
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

    async fetch() {
      this.loading = true
      const response = await this.$api.get('roadmap', {
        q: this.changesQuery[this.changesWeek],
      })

      this.loading = false

      if (!response.error) {
        this.roadmapChanges = response.data.filter((item) => item.lastVersion)
      }
    },
  },
}
</script>

<template>
  <section class="container roadmap">
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
          <Btn :to="{ name: 'roadmap', exact: true }">
            Roadmap
          </Btn>
          <Btn href="https://robertsspaceindustries.com/roadmap">
            {{ t('labels.rsiRoadmap') }}
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
            v-for="item in roadmapChanges"
            :key="item.id"
            class="col-xs-12 col-sm-6 col-xxlg-4 fade-list-item"
          >
            <RoadmapItem
              :item="item"
              without-description
            />
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
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import Btn from 'frontend/components/Btn'
import RoadmapItem from 'frontend/partials/Roadmap/RoadmapItem'
import EmptyBox from 'frontend/partials/EmptyBox'
import { subWeeks, format } from 'date-fns'

export default {
  components: {
    Loader,
    EmptyBox,
    Btn,
    RoadmapItem,
  },
  mixins: [I18n, MetaInfo],
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
          updatedAtGteq: format(subWeeks(new Date(), 1), 'YYYY-MM-DD'),
        },
      })
      this.loading = false
      if (!response.error) {
        this.roadmapChanges = response.data.filter(item => item.lastVersion)
      }
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.roadmapChanges'),
    })
  },
}
</script>

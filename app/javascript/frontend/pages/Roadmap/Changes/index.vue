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
          <Btn
            :to="{ name: 'roadmap' }"
            exact
          >
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
          class="row"
          tag="div"
          appear
        >
          <div
            v-for="item in roadmapChanges"
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
                />
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
                  </h3>
                  <p>{{ item.body }}</p>
                  <h4>
                    {{ t('labels.roadmap.lastUpdate') }}
                    <small>{{ l(item.updatedAt) }}</small>
                  </h4>
                  <ul v-if="item.lastVersion">
                    <li
                      v-for="(update, index) in updates(item.lastVersion)"
                      :key="index"
                    >
                      <template v-if="update.key === 'tasks'">
                        {{ t(`labels.roadmap.lastVersion.${update.key}.${update.change}`, {
                          value: update.count,
                        }) }}
                      </template>
                      <template v-else>
                        {{ t(`labels.roadmap.lastVersion.${update.key}`, {
                          old: update.old,
                          new: update.new,
                          count: update.count,
                        }) }}
                      </template>
                    </li>
                  </ul>
                  <b-progress :max="item.tasks">
                    <div class="progress-label">
                      {{ item.completed }} {{ t('labels.roadmap.tasks', {
                        count: item.tasks,
                      }) }}
                    </div>
                    <b-progress-bar
                      v-if="item.completed !== 0"
                      :value="item.completed"
                      :class="{
                        completed: item.completed === item.tasks
                      }"
                    />
                    <b-progress-bar
                      v-if="item.completed !== 0"
                      :value="item.completed"
                      :class="{
                        completed: item.completed === item.tasks
                      }"
                    />
                  </b-progress>
                </div>
              </div>
            </Panel>
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
import Panel from 'frontend/components/Panel'
import EmptyBox from 'frontend/partials/EmptyBox'
import { subWeeks, format } from 'date-fns'

export default {
  components: {
    Loader,
    EmptyBox,
    Btn,
    Panel,
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
    updates(lastVersion) {
      return ['tasks', 'completed', 'release'].filter(key => lastVersion[key]).map((key) => {
        const count = parseInt(lastVersion[key][1] - lastVersion[key][0], 10)
        return {
          key,
          change: (Math.sign(count) === -1) ? 'decreased' : 'increased',
          old: lastVersion[key][0],
          new: lastVersion[key][1],
          count,
        }
      })
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
        q: {
          updatedAtLteq: format(subWeeks(new Date(), 1), 'YYYY-MM-DD'),
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

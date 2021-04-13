<template>
  <section class="container progress-tracker">
    <transition-group
      v-if="collection.records.length"
      name="fade-list"
      class="row"
      tag="div"
      :appear="true"
    >
      <template v-if="grouped">
        <div
          v-for="(items, title) in groupedByTitle"
          :key="`progress-item-${title}`"
          class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
        >
          <Panel>
            <div class="panel-heading">
              <h2 class="panel-title">
                <router-link
                  v-if="model(items)"
                  :to="{ name: 'model', params: { slug: model(items).slug } }"
                  v-html="title"
                />
                <span v-else v-html="title" />
                <small>
                  {{ items[0].statusLabel }}
                </small>
              </h2>
            </div>
            <div class="teaser-panel teaser-panel-text">
              <div class="teaser-panel-body teaser-panel-item">
                <p v-html="description(items)" />
                <ul class="list-unstyled">
                  <li
                    v-for="item in sortByTeam(items)"
                    :key="item.id"
                    class="progress-tracker-item-team"
                  >
                    <b v-html="item.team" />
                    {{ item.startDateLabel }} - {{ item.endDateLabel }}
                  </li>
                </ul>
              </div>
            </div>
          </Panel>
        </div>
      </template>
      <template v-else>
        <div
          v-for="item in collection.records"
          :key="`progress-item-${item.id}`"
          class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
        >
          <Panel>
            <div class="panel-heading">
              <h2 class="panel-title">
                <router-link
                  v-if="item.model"
                  :to="{ name: 'model', params: { slug: item.model.slug } }"
                  v-html="title"
                />
                <span v-else v-html="item.title" />
                <small>
                  {{ item.statusLabel }}
                </small>
              </h2>
            </div>
            <div class="teaser-panel teaser-panel-text">
              <div class="teaser-panel-body teaser-panel-item">
                <p>{{ item.description }}</p>
                <div class="progress-tracker-item-team">
                  <b v-html="item.team" />
                  {{ item.startDateLabel }} - {{ item.endDateLabel }}
                </div>
              </div>
            </div>
          </Panel>
        </div>
      </template>
    </transition-group>
    <Loader :loading="loading" :fixed="true" />
    <div class="row">
      <div class="col-12">
        <Paginator
          v-if="collection.records.length"
          :collection="collection"
          :page="page"
        />
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/core/components/Btn'
import progressTrackerItemsCollection from 'frontend/api/collections/ProgressTrackerItems'
import { groupBy, sortBy } from 'frontend/lib/Helpers'
import Panel from 'frontend/core/components/Panel'
import Loader from 'frontend/core/components/Loader'
import Paginator from 'frontend/core/components/Paginator'
import { uniq as uniqArray } from 'frontend/utils/Array'

@Component<ProgressTracker>({
  components: {
    Btn,
    Panel,
    Loader,
    Paginator,
  },
  mixins: [MetaInfo],
})
export default class ProgressTracker extends Vue {
  collection: ProgressTrackerItemsCollection = progressTrackerItemsCollection

  progressTrackerChannel = null

  loading: boolean = true

  grouped: boolean = true

  get page() {
    return parseInt(this.routeQuery.page, 10) || 1
  }

  get groupedByTitle() {
    return groupBy(this.collection.records, 'title')
  }

  get allowedFilters() {
    return ['team', 'model_id', 'with_model', 'in_progress', 'done', 'planned']
  }

  get routeQuery() {
    return this.$route.query
  }

  get query() {
    const query = {}

    this.allowedFilters.forEach(item => {
      if (this.routeQuery[item]) {
        query[item] = this.routeQuery[item]
      } else {
        delete query[item]
      }
    })

    return query
  }

  get order() {
    return {
      title: this.routeQuery.sortByTitle,
    }
  }

  get search() {
    return this.routeQuery.search
  }

  mounted() {
    this.fetch()
    this.setupUpdates()
  }

  beforeDestroy() {
    if (this.progressTrackerChannel) {
      this.progressTrackerChannel.unsubscribe()
    }
  }

  @Watch('$route')
  onRouteChange() {
    this.fetch()
  }

  sortByTeam(items) {
    return sortBy(items, 'team')
  }

  description(items) {
    return items
      .map(item => item.description)
      .filter(uniqArray)
      .join('<br>')
  }

  model(items) {
    const itemWithModel = items.find(item => item.model)

    if (itemWithModel) {
      return itemWithModel.model
    }

    return null
  }

  setupUpdates() {
    if (this.progressTrackerChannel) {
      this.progressTrackerChannel.unsubscribe()
    }

    this.progressTrackerChannel = this.$cable.consumer.subscriptions.create(
      {
        channel: 'ProgressTrackerChannel',
      },
      {
        received: this.fetch,
      },
    )
  }

  async fetch() {
    this.loading = true

    await this.collection.findAll({
      query: this.query,
      search: this.search,
      order: this.order,
      page: this.$route.query.page,
    })

    this.loading = false
  }
}
</script>

<style lang="scss" scoped>
@import './index';
</style>

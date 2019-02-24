<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <h1 class="sr-only">
              {{ t('headlines.models') }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-6">
            <div class="page-actions page-actions-left">
              <Btn
                v-tooltip="toggleDetailsTooltip"
                :active="modelDetailsVisible"
                :aria-label="toggleDetailsTooltip"
                small
                @click.native="toggleDetails"
              >
                <i
                  :class="{
                    'fa fa-chevron-up': modelDetailsVisible,
                    'far fa-chevron-down': !modelDetailsVisible,
                  }"
                />
              </Btn>
              <Btn
                v-tooltip="toggleFiltersTooltip"
                :active="modelFilterVisible"
                :aria-label="toggleFiltersTooltip"
                small
                @click.native="toggleFilter"
              >
                <i
                  :class="{
                    fas: modelFilterVisible,
                    fal: !modelFilterVisible,
                  }"
                  class="fa-filter"
                />
              </Btn>
              <InternalLink
                :route="{name: 'compare-models'}"
                small
              >
                {{ t('actions.compare.models') }}
              </InternalLink>
            </div>
          </div>
          <div class="col-xs-12 col-md-6">
            <Paginator
              v-if="models.length"
              :page="currentPage"
              :total="totalPages"
              right
            />
          </div>
        </div>
        <div class="row">
          <transition
            name="slide"
            appear
            @before-enter="toggleFullscreen"
            @after-leave="toggleFullscreen"
          >
            <div
              v-show="modelFilterVisible"
              class="col-xs-12 col-md-3 col-xlg-2"
            >
              <ModelsFilterForm />
            </div>
          </transition>
          <div
            :class="{
              'col-md-9 col-xlg-10': !fullscreen,
            }"
            class="col-xs-12 col-animated"
          >
            <transition-group
              name="fade-list"
              class="flex-row"
              tag="div"
              appear
            >
              <div
                v-for="model in models"
                :key="model.slug"
                :class="{
                  'col-lg-4': fullscreen,
                  'col-xlg-4': !fullscreen,
                }"
                class="col-xs-12 col-sm-6 col-xxlg-2-4 fade-list-item"
              >
                <ModelPanel
                  :model="model"
                  :details="modelDetailsVisible"
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
        <div class="row">
          <div class="col-xs-12">
            <Paginator
              v-if="models.length"
              :page="currentPage"
              :total="totalPages"
              right
            />
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Pagination from 'frontend/mixins/Pagination'
import Hash from 'frontend/mixins/Hash'
import ModelPanel from 'frontend/partials/Models/Panel'
import Btn from 'frontend/components/Btn'
import InternalLink from 'frontend/components/InternalLink'
import Loader from 'frontend/components/Loader'
import Filters from 'frontend/mixins/Filters'
import EmptyBox from 'frontend/partials/EmptyBox'
import ModelsFilterForm from 'frontend/partials/Models/FilterForm'
import { mapGetters } from 'vuex'

export default {
  components: {
    ModelPanel,
    ModelsFilterForm,
    Loader,
    EmptyBox,
    Btn,
    InternalLink,
  },
  mixins: [I18n, MetaInfo, Filters, Pagination, Hash],
  data() {
    return {
      loading: false,
      models: [],
      fullscreen: false,
    }
  },
  computed: {
    ...mapGetters([
      'modelDetailsVisible',
      'modelFilterVisible',
      'mobile',
    ]),
    emptyBoxVisible() {
      return !this.loading && !this.models.length && (this.isFilterSelected
        || this.$route.query.page)
    },
    toggleDetailsTooltip() {
      if (this.modelDetailsVisible) {
        return this.t('actions.hideDetails')
      }
      return this.t('actions.showDetails')
    },
    toggleFiltersTooltip() {
      if (this.modelFilterVisible) {
        return this.t('actions.hideFilter')
      }
      return this.t('actions.showFilter')
    },
  },
  watch: {
    $route() {
      this.fetch()
    },
  },
  created() {
    this.fetch()
    if (this.mobile) {
      this.$store.commit('setModelFilterVisible', false)
    }
    this.toggleFullscreen()
  },
  methods: {
    toggleFullscreen() {
      this.fullscreen = !this.modelFilterVisible
    },
    toggleFilter() {
      this.$store.dispatch('toggleModelFilter')
    },
    toggleDetails() {
      this.$store.dispatch('toggleModelDetails')
    },
    async fetch() {
      this.loading = true
      const response = await this.$api.get('models', {
        q: this.$route.query.q,
        page: this.$route.query.page,
      })
      this.loading = false
      if (!response.error) {
        this.models = response.data
        this.scrollToAnchor()
      }
      this.setPages(response.meta)
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.models'),
    })
  },
}
</script>

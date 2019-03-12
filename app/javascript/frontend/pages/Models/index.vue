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
                v-if="!modelFleetchartVisible"
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
                    far: !modelFilterVisible,
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
              <DownloadScreenshotBtn
                v-if="modelFleetchartVisible"
                element="#fleetchart"
                filename="ships-fleetchart"
              />
              <Btn
                small
                @click.native="toggleFleetchart"
              >
                <template v-if="modelFleetchartVisible">
                  {{ t('actions.hideFleetchart') }}
                </template>
                <template v-else>
                  {{ t('actions.showFleetchart') }}
                </template>
              </Btn>
            </div>
          </div>
          <div class="col-xs-12 col-md-6">
            <Paginator
              v-if="!modelFleetchartVisible && models.length"
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
            <transition
              name="fade"
              appear
            >
              <div
                v-if="modelFleetchartVisible && fleetchartModels.length"
                class="row"
              >
                <div class="col-xs-12 col-md-4 col-md-offset-4 fleetchart-slider">
                  <FleetchartSlider scale-key="ModelFleetchartScale" />
                </div>
              </div>
            </transition>
            <div
              v-if="modelFleetchartVisible"
              class="row"
            >
              <div class="col-xs-12 fleetchart-wrapper">
                <transition-group
                  id="fleetchart"
                  name="fade-list"
                  class="flex-row fleetchart"
                  tag="div"
                  appear
                >
                  <FleetchartItem
                    v-for="model in fleetchartModels"
                    :key="`fleetchart-${model.slug}`"
                    :model="model"
                    :scale="ModelFleetchartScale"
                  />
                </transition-group>
              </div>
            </div>
            <transition-group
              v-else
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
              v-if="!modelFleetchartVisible && models.length"
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
import { mapGetters } from 'vuex'
import Btn from 'frontend/components/Btn'
import InternalLink from 'frontend/components/InternalLink'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import Loader from 'frontend/components/Loader'
import ModelPanel from 'frontend/partials/Models/Panel'
import EmptyBox from 'frontend/partials/EmptyBox'
import ModelsFilterForm from 'frontend/partials/Models/FilterForm'
import FleetchartItem from 'frontend/partials/Models/FleetchartItem'
import FleetchartSlider from 'frontend/partials/FleetchartSlider'
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Filters from 'frontend/mixins/Filters'
import Pagination from 'frontend/mixins/Pagination'
import Hash from 'frontend/mixins/Hash'

export default {
  components: {
    Btn,
    InternalLink,
    DownloadScreenshotBtn,
    Loader,
    ModelPanel,
    EmptyBox,
    ModelsFilterForm,
    FleetchartItem,
    FleetchartSlider,
  },
  mixins: [I18n, MetaInfo, Filters, Pagination, Hash],
  data() {
    return {
      loading: true,
      models: [],
      fullscreen: false,
      fleetchartModels: [],
    }
  },
  computed: {
    ...mapGetters([
      'modelDetailsVisible',
      'modelFilterVisible',
      'modelFleetchartVisible',
      'ModelFleetchartScale',
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

    if (this.$route.query.fleetchart && !this.modelFleetchartVisible) {
      this.$store.dispatch('toggleModelFleetchart')
    }

    if (this.mobile) {
      this.$store.commit('setModelFilterVisible', false)
    }

    this.toggleFullscreen()
  },
  methods: {
    fetch() {
      this.fetchModels()
      this.fetchFleetchart()
    },
    toggleFullscreen() {
      this.fullscreen = !this.modelFilterVisible
    },
    toggleFleetchart() {
      this.$store.dispatch('toggleModelFleetchart')

      if (this.$route.query.fleetchart && !this.modelFleetchartVisible) {
        const query = JSON.parse(JSON.stringify(this.$route.query))

        delete query.fleetchart

        this.$router.replace({
          name: this.$route.name,
          query,
        })
      }
    },
    toggleFilter() {
      this.$store.dispatch('toggleModelFilter')
    },
    toggleDetails() {
      this.$store.dispatch('toggleModelDetails')
    },
    async fetchModels() {
      this.loading = true
      const response = await this.$api.get('models', {
        q: this.$route.query.q,
        page: this.$route.query.page,
      })
      if (!response.error) {
        this.models = response.data
        this.scrollToAnchor()
      }
      this.setPages(response.meta)
      this.restLoading()
    },
    async fetchFleetchart() {
      this.loading = true
      const response = await this.$api.get('models/fleetchart', {
        q: this.$route.query.q,
      })
      if (!response.error) {
        this.fleetchartModels = response.data
      }
      this.restLoading()
    },
    resetLoading() {
      setTimeout(() => {
        this.loading = false
      }, 300)
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.models'),
    })
  },
}
</script>

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
                v-if="!fleetchartVisible"
                v-tooltip="toggleDetailsTooltip"
                :active="detailsVisible"
                :aria-label="toggleDetailsTooltip"
                size="small"
                @click.native="toggleDetails"
              >
                <i
                  :class="{
                    'fa fa-chevron-up': detailsVisible,
                    'far fa-chevron-down': !detailsVisible,
                  }"
                />
              </Btn>
              <Btn
                v-tooltip="toggleFiltersTooltip"
                :active="filterVisible"
                :aria-label="toggleFiltersTooltip"
                size="small"
                @click.native="toggleFilter"
              >
                <i
                  :class="{
                    fas: isFilterSelected,
                    far: !isFilterSelected,
                  }"
                  class="fa-filter"
                />
              </Btn>
              <Btn
                :to="{name: 'compare-models'}"
                size="small"
              >
                {{ t('actions.compare.models') }}
              </Btn>
              <DownloadScreenshotBtn
                v-if="fleetchartVisible"
                element="#fleetchart"
                filename="ships-fleetchart"
              />
              <Btn
                size="small"
                @click.native="toggleFleetchart"
              >
                <template v-if="fleetchartVisible">
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
              v-if="!fleetchartVisible && models.length"
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
              v-show="filterVisible"
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
                v-if="fleetchartVisible && fleetchartModels.length"
                class="row"
              >
                <div class="col-xs-12 col-md-4 col-md-offset-4 fleetchart-slider">
                  <FleetchartSlider
                    :initial-scale="fleetchartScale"
                    @change="updateScale"
                  />
                </div>
              </div>
            </transition>
            <div
              v-if="fleetchartVisible"
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
                    :scale="fleetchartScale"
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
                  :details="detailsVisible"
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
              v-if="!fleetchartVisible && models.length"
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
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import Loader from 'frontend/components/Loader'
import ModelPanel from 'frontend/components/Models/Panel'
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
      'mobile',
    ]),
    ...mapGetters('models', [
      'detailsVisible',
      'filterVisible',
      'fleetchartVisible',
      'fleetchartScale',
    ]),
    emptyBoxVisible() {
      return !this.loading && !this.models.length && (this.isFilterSelected
        || this.$route.query.page)
    },
    toggleDetailsTooltip() {
      if (this.detailsVisible) {
        return this.t('actions.hideDetails')
      }
      return this.t('actions.showDetails')
    },
    toggleFiltersTooltip() {
      if (this.filterVisible) {
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

    if (this.$route.query.fleetchart && !this.fleetchartVisible) {
      this.$store.dispatch('models/toggleFleetchart')
    }

    if (this.mobile) {
      this.$store.commit('models/setFilterVisible', false)
    }

    this.toggleFullscreen()
  },
  methods: {
    updateScale(value) {
      this.$store.commit('models/setFleetchartScale', value)
    },
    fetch() {
      this.fetchModels()
      this.fetchFleetchart()
    },
    toggleFullscreen() {
      this.fullscreen = !this.filterVisible
    },
    toggleFleetchart() {
      this.$store.dispatch('models/toggleFleetchart')

      if (this.$route.query.fleetchart && !this.fleetchartVisible) {
        const query = JSON.parse(JSON.stringify(this.$route.query))

        delete query.fleetchart

        this.$router.replace({
          name: this.$route.name,
          query,
        })
      }
    },
    toggleFilter() {
      this.$store.dispatch('models/toggleFilter')
    },
    toggleDetails() {
      this.$store.dispatch('models/toggleDetails')
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
      this.resetLoading()
    },
    async fetchFleetchart() {
      this.loading = true
      const response = await this.$api.get('models/fleetchart', {
        q: this.$route.query.q,
      })
      if (!response.error) {
        this.fleetchartModels = response.data
      }
      this.resetLoading()
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

<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12 col-md-8">
            <h1 class="sr-only">{{ t('headlines.ships') }}</h1>
          </div>
          <div class="col-xs-12 col-md-4 text-right">
            <button
              class="btn btn-link btn-filter hidden-md hidden-lg"
              @click="openFilter"
            >
              <i
                v-if="isFilterSelected"
                class="fas fa-filter"
              />
              <i
                v-else
                class="fal fa-filter"
              />
            </button>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-6">
            <Paginator
              v-if="models.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
          <div class="col-xs-12 col-md-6">
            <div class="page-actions">
              <Btn
                v-tooltip="toggleDetailsTooltip"
                :active="modelDetails"
                :aria-label="toggleDetailsTooltip"
                small
                @click.native="toggleDetails"
              >
                <i class="fas fa-list" />
              </Btn>
              <Btn
                v-tooltip="toggleFiltersTooltip"
                :active="modelFilterVisible"
                :aria-label="toggleFiltersTooltip"
                class="hidden-xs hidden-sm"
                small
                @click.native="toggleFilter"
              >
                <i
                  v-if="isFilterSelected"
                  class="fas fa-filter"
                />
                <i
                  v-else
                  class="fal fa-filter"
                />
              </Btn>
            </div>
          </div>
        </div>
        <div class="row">
          <div
            :class="{
              'col-md-9 col-xlg-10': modelFilterVisible,
            }"
            class="col-xs-12"
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
                  'col-lg-4 col-xlg-3 col-xxlg-2': !modelFilterVisible,
                  'col-xlg-4 col-xxlg-3': modelFilterVisible,
                }"
                class="col-xs-12 col-sm-6 fade-list-item"
              >
                <ModelPanel
                  :model="model"
                  :details="modelDetails"
                />
              </div>
            </transition-group>
            <EmptyBox v-if="emptyBoxVisible" />
            <Loader
              v-if="loading"
              fixed
            />
          </div>
          <transition
            name="fade"
            appear
          >
            <div
              v-show="modelFilterVisible"
              class="hidden-xs hidden-sm col-md-3 col-xlg-2"
            >
              <ModelsFilterForm :filters="filters" />
            </div>
          </transition>
        </div>
        <div class="row">
          <div class="col-xs-12">
            <Paginator
              v-if="models.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
        </div>
        <ModelsFilterModal
          ref="filterModal"
          :filters="filters"
        />
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
import Loader from 'frontend/components/Loader'
import Filters from 'frontend/mixins/Filters'
import EmptyBox from 'frontend/partials/EmptyBox'
import ModelsFilterModal from 'frontend/partials/Models/FilterModal'
import ModelsFilterForm from 'frontend/partials/Models/FilterForm'
import { mapGetters } from 'vuex'

export default {
  components: {
    ModelPanel,
    ModelsFilterModal,
    ModelsFilterForm,
    Loader,
    EmptyBox,
    Btn,
  },
  mixins: [I18n, MetaInfo, Filters, Pagination, Hash],
  data() {
    return {
      loading: false,
      models: [],
      filters: [],
    }
  },
  computed: {
    ...mapGetters([
      'modelDetails',
      'modelFilterVisible',
    ]),
    emptyBoxVisible() {
      return !this.loading && !this.models.length && (this.isFilterSelected
        || this.$route.query.page)
    },
    toggleDetailsTooltip() {
      if (this.hangarDetails) {
        return this.t('actions.hideDetails')
      }
      return this.t('actions.showDetails')
    },
    toggleFiltersTooltip() {
      if (this.hangarFilterVisible) {
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
    this.fetchFilters()
  },
  methods: {
    toggleFilter() {
      this.$store.commit('toggleModelFilter')
    },
    toggleDetails() {
      this.$store.commit('toggleModelDetails')
    },
    openFilter() {
      this.$refs.filterModal.open()
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
    async fetchFilters() {
      const response = await this.$api.get('models/filters', {})
      if (!response.error) {
        this.filters = response.data
      }
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.models'),
    })
  },
}
</script>

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
            <EmptyBox v-if="!loading && !models.length && isFilterSelected" />
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
              <ModelsFilterForm />
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
        />
      </div>
    </div>
  </section>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Pagination from 'frontend/mixins/Pagination'
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
  mixins: [I18n, MetaInfo, Filters, Pagination],
  data() {
    return {
      loading: false,
      models: [],
    }
  },
  computed: {
    ...mapGetters([
      'modelDetails',
      'modelFilterVisible',
    ]),
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
    fetch() {
      this.loading = true
      this.$api.get('models', {
        q: this.$route.query.q,
        page: this.$route.query.page,
      }, (args) => {
        this.loading = false

        if (!args.error) {
          this.models = args.data
          this.$comlink.$emit('fetched')
        }
        this.setPages(args.meta)
      })
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.models'),
    })
  },
}
</script>

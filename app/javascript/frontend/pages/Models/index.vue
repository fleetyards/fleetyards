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
          <div class="col-xs-12 col-md-9 col-xlg-10">
            <transition-group
              name="fade-list"
              class="flex-row"
              tag="div"
              appear
            >
              <div
                v-for="model in models"
                :key="model.slug"
                class="col-xs-12 col-sm-6 col-xlg-4 fade-list-item"
              >
                <ModelPanel
                  :model="model"
                  details
                />
              </div>
            </transition-group>
            <EmptyBox v-if="!loading && !models.length && isFilterSelected" />
            <Loader
              v-if="loading"
              fixed
            />
          </div>
          <div class="hidden-xs hidden-sm col-md-3 col-xlg-2">
            <ModelsFilterForm />
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
import ModelPanel from 'frontend/partials/Models/Panel'
import Loader from 'frontend/components/Loader'
import Filters from 'frontend/mixins/Filters'
import EmptyBox from 'frontend/partials/EmptyBox'
import ModelsFilterModal from 'frontend/partials/Models/FilterModal'
import ModelsFilterForm from 'frontend/partials/Models/FilterForm'

export default {
  components: {
    ModelPanel,
    ModelsFilterModal,
    ModelsFilterForm,
    Loader,
    EmptyBox,
  },
  mixins: [I18n, MetaInfo, Filters],
  data() {
    return {
      loading: false,
      models: [],
    }
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
    openFilter() {
      this.$refs.filterModal.open()
    },
    fetch() {
      this.loading = true
      this.$api.get('models', {
        q: this.$route.query.q,
      }, (args) => {
        this.loading = false

        if (this.$refs.infiniteLoading) {
          this.$refs.infiniteLoading.$emit('$InfiniteLoading:reset')
        }

        if (!args.error) {
          this.models = args.data
        }
      })
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.models')
    })
  },
}
</script>

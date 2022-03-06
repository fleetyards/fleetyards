<template>
  <section class="container">
    <div class="row">
      <div class="col-12 col-lg-12">
        <div class="row">
          <div class="col-12">
            <h1 class="sr-only">
              {{ $t('headlines.models.index') }}
            </h1>
          </div>
        </div>
        <div class="page-actions page-actions-right">
          <Btn
            data-test="model-compare-link"
            :to="{
              name: 'models-compare',
            }"
          >
            <i class="fad fa-exchange" />
            {{ $t('nav.compare.models') }}
          </Btn>
          <Btn data-test="fleetchart-link" @click.native="toggleFleetchart">
            <i class="fad fa-starship" />
            {{ $t('labels.fleetchart') }}
          </Btn>
        </div>
      </div>
    </div>

    <FilteredList
      key="models"
      :collection="collection"
      :name="$route.name"
      :route-query="$route.query"
      :hash="$route.hash"
      :paginated="true"
      :hide-loading="fleetchartVisible"
    >
      <template slot="actions">
        <BtnDropdown size="small">
          <Btn
            :aria-label="toggleGridViewTooltip"
            size="small"
            variant="dropdown"
            @click.native="toggleGridView"
          >
            <i v-if="gridView" class="fad fa-list" />
            <i v-else class="fas fa-th" />
            <span>{{ toggleGridViewTooltip }}</span>
          </Btn>

          <Btn
            v-if="!gridView"
            :aria-label="toggleTableSlimTooltip"
            size="small"
            variant="dropdown"
            @click.native="toggleTableSlim"
          >
            <i v-if="tableSlim" class="fas fa-bars" />
            <i v-else class="fal fa-bars" />
            <span>{{ toggleTableSlimTooltip }}</span>
          </Btn>

          <Btn
            v-if="gridView"
            :active="detailsVisible"
            :aria-label="toggleDetailsTooltip"
            size="small"
            variant="dropdown"
            @click.native="toggleDetails"
          >
            <i class="fad fa-info-square" />
            <span>{{ toggleDetailsTooltip }}</span>
          </Btn>
        </BtnDropdown>
      </template>

      <ModelsFilterForm slot="filter" />

      <template #default="{ records, loading, filterVisible, primaryKey }">
        <FilteredGrid
          v-if="gridView"
          :records="records"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record }">
            <ModelPanel :model="record" :details="detailsVisible" />
          </template>
        </FilteredGrid>

        <ModelsTable
          v-else
          :models="records"
          :primary-key="primaryKey"
          :slim="tableSlim"
        />

        <FleetchartApp
          :items="records"
          namespace="models"
          :loading="loading"
          download-name="ships-fleetchart"
        />
      </template>
    </FilteredList>
  </section>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import Btn from '@/frontend/core/components/Btn/index.vue'
import BtnDropdown from '@/frontend/core/components/BtnDropdown/index.vue'
import FilteredList from '@/frontend/core/components/FilteredList/index.vue'
import FilteredGrid from '@/frontend/core/components/FilteredGrid/index.vue'
import ModelPanel from '@/frontend/components/Models/Panel/index.vue'
import ModelsTable from '@/frontend/components/Models/Table/index.vue'
import ModelsFilterForm from '@/frontend/components/Models/FilterForm/index.vue'
import FleetchartApp from '@/frontend/components/Fleetchart/App/index.vue'
import MetaInfo from '@/frontend/mixins/MetaInfo'
import modelsCollection from '@/frontend/api/collections/Models'

export default {
  name: 'ModelsPage',

  components: {
    Btn,
    BtnDropdown,
    FilteredGrid,
    FilteredList,
    FleetchartApp,
    ModelPanel,
    ModelsFilterForm,
    ModelsTable,
  },

  mixins: [MetaInfo],

  data() {
    return {
      collection: modelsCollection,
    }
  },

  computed: {
    ...mapGetters('models', [
      'detailsVisible',
      'fleetchartVisible',
      'perPage',
      'gridView',
      'tableSlim',
    ]),

    filters() {
      return {
        filters: this.$route.query.q,
        page: this.$route.query.page,
      }
    },

    toggleDetailsTooltip() {
      if (this.detailsVisible) {
        return this.$t('actions.hideDetails')
      }

      return this.$t('actions.showDetails')
    },

    toggleGridViewTooltip() {
      if (this.gridView) {
        return this.$t('actions.showTableView')
      }

      return this.$t('actions.showGridView')
    },

    toggleTableSlimTooltip() {
      if (this.tableSlim) {
        return this.$t('actions.showExpandedList')
      }

      return this.$t('actions.showCompactList')
    },
  },

  watch: {
    perPage() {
      this.collection.findAll(this.filters)
    },
  },

  methods: {
    ...mapActions('models', [
      'toggleDetails',
      'toggleGridView',
      'toggleTableSlim',
      'toggleFleetchart',
    ]),
  },
}
</script>

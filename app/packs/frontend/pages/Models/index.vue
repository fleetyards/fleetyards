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

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Action, Getter } from 'vuex-class'
import Btn from 'frontend/core/components/Btn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import FilteredList from 'frontend/core/components/FilteredList'
import FilteredGrid from 'frontend/core/components/FilteredGrid'
import ModelPanel from 'frontend/components/Models/Panel'
import ModelsTable from 'frontend/components/Models/Table'
import ModelsFilterForm from 'frontend/components/Models/FilterForm'
import FleetchartApp from 'frontend/components/Fleetchart/App'
import MetaInfo from 'frontend/mixins/MetaInfo'
import modelsCollection, {
  ModelsCollection,
} from 'frontend/api/collections/Models'
import HangarItemsMixin from 'frontend/mixins/HangarItems'

@Component<Models>({
  components: {
    Btn,
    BtnDropdown,
    FilteredList,
    FilteredGrid,
    FleetchartApp,
    ModelPanel,
    ModelsFilterForm,
    ModelsTable,
  },
  mixins: [MetaInfo, HangarItemsMixin],
})
export default class Models extends Vue {
  collection: ModelsCollection = modelsCollection

  @Getter('detailsVisible', { namespace: 'models' }) detailsVisible

  @Getter('fleetchartVisible', { namespace: 'models' }) fleetchartVisible

  @Getter('perPage', { namespace: 'models' }) perPage

  @Getter('gridView', { namespace: 'models' }) gridView

  @Getter('tableSlim', { namespace: 'models' }) tableSlim

  @Action('toggleDetails', { namespace: 'models' }) toggleDetails: any

  @Action('toggleGridView', { namespace: 'models' }) toggleGridView: any

  @Action('toggleTableSlim', { namespace: 'models' }) toggleTableSlim: any

  @Action('toggleFleetchart', { namespace: 'models' }) toggleFleetchart: any

  get toggleDetailsTooltip() {
    if (this.detailsVisible) {
      return this.$t('actions.hideDetails')
    }

    return this.$t('actions.showDetails')
  }

  get toggleGridViewTooltip() {
    if (this.gridView) {
      return this.$t('actions.showTableView')
    }

    return this.$t('actions.showGridView')
  }

  get toggleTableSlimTooltip() {
    if (this.tableSlim) {
      return this.$t('actions.showExpandedList')
    }

    return this.$t('actions.showCompactList')
  }

  get filters() {
    return {
      filters: this.$route.query.q,
      page: this.$route.query.page,
    }
  }

  @Watch('perPage')
  onPerPageChange() {
    this.collection.findAll(this.filters)
  }
}
</script>

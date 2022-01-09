<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <h1 class="sr-only">
          {{ $t('headlines.models.index') }}
        </h1>
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
        <Btn
          size="small"
          data-test="fleetchart-link"
          @click.native="toggleFleetchart"
        >
          <i class="fad fa-starship" />
          {{ $t('labels.fleetchart') }}
        </Btn>
        <Btn
          :active="detailsVisible"
          :aria-label="toggleDetailsTooltip"
          size="small"
          @click.native="toggleDetails"
        >
          <i class="fad fa-info-square" />
          {{ toggleDetailsTooltip }}
        </Btn>
      </template>

      <ModelsFilterForm slot="filter" />

      <template #default="{ records, loading, filterVisible, primaryKey }">
        <FilteredGrid
          :records="records"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record }">
            <ModelPanel :model="record" :details="detailsVisible" />
          </template>
        </FilteredGrid>

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
  },
  mixins: [MetaInfo, HangarItemsMixin],
})
export default class Models extends Vue {
  collection: ModelsCollection = modelsCollection

  @Getter('detailsVisible', { namespace: 'models' }) detailsVisible

  @Getter('fleetchartVisible', { namespace: 'models' }) fleetchartVisible

  @Getter('perPage', { namespace: 'models' }) perPage

  @Action('toggleDetails', { namespace: 'models' }) toggleDetails: any

  @Action('toggleFleetchart', { namespace: 'models' }) toggleFleetchart: any

  get toggleDetailsTooltip() {
    if (this.detailsVisible) {
      return this.$t('actions.hideDetails')
    }

    return this.$t('actions.showDetails')
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

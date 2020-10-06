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
      :collection="collection"
      :name="$route.name"
      :route-query="$route.query"
      :hash="$route.hash"
      :paginated="true"
    >
      <template slot="actions">
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

      <template #record="{ record }">
        <ModelPanel :model="record" :details="detailsVisible" />
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { Action, Getter } from 'vuex-class'
import Btn from 'frontend/core/components/Btn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import FilteredList from 'frontend/core/components/FilteredList'
import ModelPanel from 'frontend/components/Models/Panel'
import ModelsFilterForm from 'frontend/components/Models/FilterForm'
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
    ModelPanel,
    ModelsFilterForm,
  },
  mixins: [MetaInfo, HangarItemsMixin],
})
export default class Models extends Vue {
  collection: ModelsCollection = modelsCollection

  @Action('toggleDetails', { namespace: 'models' }) toggleDetails: any

  @Getter('detailsVisible', { namespace: 'models' }) detailsVisible

  get toggleDetailsTooltip() {
    if (this.detailsVisible) {
      return this.$t('actions.hideDetails')
    }

    return this.$t('actions.showDetails')
  }
}
</script>

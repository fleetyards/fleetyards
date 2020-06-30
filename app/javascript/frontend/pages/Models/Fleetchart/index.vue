<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1 class="sr-only">
          {{ $t('headlines.models.fleetchart') }}
        </h1>
      </div>
    </div>
    <FilteredList
      :collection="collection"
      collection-method="findAllFleetchart"
      :name="$route.name"
      :route-query="$route.query"
      :hash="$route.hash"
    >
      <template slot="actions">
        <DownloadScreenshotBtn
          element="#fleetchart"
          filename="ships-fleetchart"
          size="small"
          :with-label="false"
        />
      </template>

      <ModelsFilterForm slot="filter" />

      <template v-slot:default="{ records }">
        <transition name="fade" appear>
          <div v-if="records.length" class="row justify-content-lg-center">
            <div class="col-12 col-lg-4 fleetchart-slider">
              <FleetchartSlider
                :initial-scale="fleetchartScale"
                @change="updateScale"
              />
            </div>
          </div>
        </transition>

        <FleetchartList :items="records" :scale="fleetchartScale" />
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { Mutation, Getter } from 'vuex-class'
import FilteredList from 'frontend/core/components/FilteredList'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import ModelsFilterForm from 'frontend/components/Models/FilterForm'
import FleetchartList from 'frontend/components/Fleetchart/List'
import FleetchartSlider from 'frontend/components/Fleetchart/Slider'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Filters from 'frontend/mixins/Filters'
import BreadCrumbs from 'frontend/core/components/BreadCrumbs'
import ModelsCollection from 'frontend/api/collections/Models'

@Component<ModelsFleetchart>({
  components: {
    FilteredList,
    DownloadScreenshotBtn,
    ModelsFilterForm,
    FleetchartList,
    FleetchartSlider,
    BreadCrumbs,
  },
  mixins: [MetaInfo, Filters],
})
export default class ModelsFleetchart extends Vue {
  collection = ModelsCollection

  @Mutation('setFleetchartScale', { namespace: 'models' }) updateScale: any

  @Getter('fleetchartScale', { namespace: 'models' }) fleetchartScale

  get crumbs() {
    return [
      {
        to: {
          name: 'models',
        },
        label: this.$t('nav.models.index'),
      },
    ]
  }
}
</script>

<template>
  <router-view v-if="isSubRoute" />
  <section v-else class="container">
    <div class="row">
      <div class="col-12">
        <h1 class="sr-only">
          {{ $t('headlines.stations') }}
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
      <FilterForm slot="filter" />

      <template v-slot:default="{ filterVisible, records }">
        <transition-group name="fade-list" class="row" tag="div" :appear="true">
          <div
            v-for="(record, index) in records"
            :key="`${record.id}-${index}`"
            :class="{
              'col-3xl-6': !filterVisible,
            }"
            class="col-12 fade-list-item"
          >
            <StationPanel :station="record" />
          </div>
        </transition-group>
      </template>
    </FilteredList>
  </section>
</template>

<script>
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import MetaInfo from 'frontend/mixins/MetaInfo'
import FilteredList from 'frontend/components/FilteredList'
import StationPanel from 'frontend/components/Stations/Panel'
import FilterForm from 'frontend/partials/Stations/FilterForm'
import stationsCollection from 'frontend/collections/Stations'

@Component<Stations>({
  components: {
    FilteredList,
    StationPanel,
    FilterForm,
  },
  mixins: [MetaInfo],
})
export default class Stations extends Vue {
  collection: StationsCollection = stationsCollection

  get isSubRoute() {
    return this.$route.name !== 'stations'
  }
}
</script>

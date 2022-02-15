<template>
  <div>
    <FilteredList
      key="fleet-public-ships"
      :collection="collection"
      :name="$route.name"
      :route-query="$route.query"
      :params="routeParams"
      :hash="$route.hash"
      :paginated="true"
      :hide-loading="fleetchartVisible"
    >
      <template slot="actions">
        <BtnDropdown size="small">
          <template v-if="mobile">
            <Btn
              size="small"
              variant="dropdown"
              data-test="fleetchart-link"
              @click.native="toggleFleetchart"
            >
              <i class="fad fa-starship" />
              <span>{{ $t('labels.fleetchart') }}</span>
            </Btn>

            <hr />
          </template>
          <Btn
            :active="detailsVisible"
            :aria-label="toggleDetailsTooltip"
            size="small"
            variant="dropdown"
            @click.native="toggleDetails"
          >
            <i class="fad fa-info-square" />
            <span>{{ toggleDetailsTooltip }}</span>
          </Btn>

          <Btn size="small" variant="dropdown" @click.native="toggleGrouped">
            <template v-if="grouped">
              <i class="fas fa-square" />
              <span>{{ $t('actions.ungrouped') }}</span>
            </template>
            <template v-else>
              <i class="fas fa-th-large" />
              <span>{{ $t('actions.groupedByModel') }}</span>
            </template>
          </Btn>
        </BtnDropdown>
      </template>

      <PublicFleetVehiclesFilterForm slot="filter" />

      <template #default="{ records, loading, filterVisible, primaryKey }">
        <FilteredGrid
          :records="records"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record }">
            <FleetVehiclePanel
              :fleet-vehicle="record"
              :details="detailsVisible"
              :show-owner="false"
            />
          </template>
        </FilteredGrid>

        <FleetchartApp
          :items="records"
          namespace="publicFleet"
          :loading="loading"
          :download-name="`${fleet.slug}-fleetchart`"
        />
      </template>
    </FilteredList>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import FilteredList from '@/frontend/core/components/FilteredList'
import FilteredGrid from '@/frontend/core/components/FilteredGrid'
import Btn from '@/frontend/core/components/Btn'
import BtnDropdown from '@/frontend/core/components/BtnDropdown'
import FleetVehiclePanel from '@/frontend/components/Fleets/VehiclePanel'
import FleetchartApp from '@/frontend/components/Fleetchart/App'
import PublicFleetVehiclesFilterForm from '@/frontend/components/Fleets/PublicFilterForm'
import publicFleetVehiclesCollection from '@/frontend/api/collections/PublicFleetVehicles'

export default {
  name: 'FleetPublicShipsList',

  components: {
    Btn,
    BtnDropdown,
    FilteredList,
    FilteredGrid,
    FleetVehiclePanel,
    PublicFleetVehiclesFilterForm,
    FleetchartApp,
  },

  props: {
    fleet: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      collection: publicFleetVehiclesCollection,
    }
  },

  computed: {
    ...mapGetters(['mobile']),

    ...mapGetters('publicFleet', [
      'grouped',
      'detailsVisible',
      'fleetchartVisible',
      'perPage',
    ]),

    toggleDetailsTooltip() {
      if (this.detailsVisible) {
        return this.$t('actions.hideDetails')
      }
      return this.$t('actions.showDetails')
    },

    routeParams() {
      return {
        ...this.$route.params,
        grouped: this.grouped,
      }
    },

    filters() {
      return {
        slug: this.fleet.slug,
        grouped: this.grouped,
        page: this.$route.query.page,
      }
    },
  },

  watch: {
    grouped() {
      this.fetch()
    },

    perPage() {
      this.fetch()
    },
  },

  methods: {
    ...mapActions('publicFleet', [
      'toggleFleetchart',
      'toggleDetails',
      'toggleGrouped',
    ]),

    async fetch() {
      await this.collection.findAll(this.filters)
    },
  },
}
</script>

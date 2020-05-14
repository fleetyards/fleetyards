<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1 class="sr-only">
          {{ $t('headlines.models') }}
        </h1>
      </div>
    </div>
    <FilteredList>
      <template slot="actions">
        <BtnDropdown size="small">
          <Btn :to="{ name: 'models-compare' }" size="small" variant="link">
            <i class="fad fa-exchange" />
            {{ $t('actions.compare.models') }}
          </Btn>

          <Btn size="small" variant="link" @click.native="toggleFleetchart">
            <template v-if="fleetchartVisible">
              <i class="fas fa-th" />
              {{ $t('actions.hideFleetchart') }}
            </template>
            <template v-else>
              <i class="fad fa-starship" />
              {{ $t('actions.showFleetchart') }}
            </template>
          </Btn>

          <DownloadScreenshotBtn
            v-if="fleetchartVisible"
            element="#fleetchart"
            filename="ships-fleetchart"
            size="small"
            variant="link"
            :show-tooltip="false"
          />

          <Btn
            v-else
            :active="detailsVisible"
            :aria-label="toggleDetailsTooltip"
            size="small"
            variant="link"
            @click.native="toggleDetails"
          >
            <i class="fad fa-info-square" />
            {{ toggleDetailsTooltip }}
          </Btn>
        </BtnDropdown>
      </template>

      <Paginator
        v-if="!fleetchartVisible && models.length"
        slot="pagination-top"
        :page="currentPage"
        :total="totalPages"
        :center="true"
      />

      <ModelsFilterForm slot="filter" />

      <template v-slot:default="{ filterVisible }">
        <transition name="fade" appear>
          <div v-if="fleetchartVisible && fleetchartModels.length" class="row">
            <div class="col-xs-12 col-md-4 col-md-offset-4 fleetchart-slider">
              <FleetchartSlider
                :initial-scale="fleetchartScale"
                @change="updateScale"
              />
            </div>
          </div>
        </transition>

        <FleetchartList
          v-if="fleetchartVisible"
          :items="fleetchartModels"
          :scale="fleetchartScale"
        />

        <transition-group
          v-else
          name="fade-list"
          class="flex-row"
          tag="div"
          appear
        >
          <div
            v-for="model in models"
            :key="model.slug"
            :class="{
              'col-lg-4': filterVisible,
              'col-xlg-4': !filterVisible,
            }"
            class="col-xs-12 col-sm-6 col-xxlg-2-4 fade-list-item"
          >
            <ModelPanel :model="model" :details="detailsVisible" />
          </div>
        </transition-group>

        <EmptyBox :visible="emptyBoxVisible" />

        <Loader :loading="loading" fixed />
      </template>

      <Paginator
        v-if="!fleetchartVisible && models.length"
        slot="pagination-bottom"
        :page="currentPage"
        :total="totalPages"
        :center="true"
      />
    </FilteredList>
  </section>
</template>

<script>
import { mapGetters } from 'vuex'
import Btn from 'frontend/components/Btn'
import BtnDropdown from 'frontend/components/BtnDropdown'
import FilteredList from 'frontend/components/FilteredList'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import Loader from 'frontend/components/Loader'
import ModelPanel from 'frontend/components/Models/Panel'
import EmptyBox from 'frontend/partials/EmptyBox'
import ModelsFilterForm from 'frontend/partials/Models/FilterForm'
import FleetchartList from 'frontend/partials/Fleetchart/List'
import FleetchartSlider from 'frontend/partials/Fleetchart/Slider'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Filters from 'frontend/mixins/Filters'
import Pagination from 'frontend/mixins/Pagination'
import Hash from 'frontend/mixins/Hash'

export default {
  name: 'Models',

  components: {
    Btn,
    BtnDropdown,
    FilteredList,
    DownloadScreenshotBtn,
    Loader,
    ModelPanel,
    EmptyBox,
    ModelsFilterForm,
    FleetchartList,
    FleetchartSlider,
  },

  mixins: [MetaInfo, Filters, Pagination, Hash],

  data() {
    return {
      loading: true,
      models: [],
      fleetchartModels: [],
    }
  },

  computed: {
    ...mapGetters('models', [
      'detailsVisible',
      'fleetchartVisible',
      'fleetchartScale',
    ]),

    emptyBoxVisible() {
      return (
        !this.loading &&
        !this.models.length &&
        (this.isFilterSelected || this.$route.query.page)
      )
    },

    toggleDetailsTooltip() {
      if (this.detailsVisible) {
        return this.$t('actions.hideDetails')
      }
      return this.$t('actions.showDetails')
    },
  },

  watch: {
    $route() {
      this.fetch()
    },
  },

  mounted() {
    this.fetch()

    if (this.$route.query.fleetchart && !this.fleetchartVisible) {
      this.$store.dispatch('models/toggleFleetchart')
    }
  },

  methods: {
    updateScale(value) {
      this.$store.commit('models/setFleetchartScale', value)
    },

    fetch() {
      this.fetchModels()
      this.fetchFleetchart()
    },

    toggleFleetchart() {
      this.$store.dispatch('models/toggleFleetchart')

      if (this.$route.query.fleetchart && !this.fleetchartVisible) {
        const query = JSON.parse(JSON.stringify(this.$route.query))

        delete query.fleetchart

        this.$router.replace({
          name: this.$route.name,
          query,
        })
      }
    },

    toggleDetails() {
      this.$store.dispatch('models/toggleDetails')
    },

    async fetchModels() {
      this.loading = true

      const response = await this.$api.get('models', {
        q: this.$route.query.q,
        page: this.$route.query.page,
      })

      if (!response.error) {
        this.models = response.data
        this.scrollToAnchor()
      }

      this.setPages(response.meta)
      this.resetLoading()
    },

    async fetchFleetchart() {
      this.loading = true

      const response = await this.$api.get('models/fleetchart', {
        q: this.$route.query.q,
      })

      if (!response.error) {
        this.fleetchartModels = response.data
      }

      this.resetLoading()
    },

    resetLoading() {
      setTimeout(() => {
        this.loading = false
      }, 300)
    },
  },
}
</script>

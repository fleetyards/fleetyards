<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1 class="sr-only">{{ t('headlines.shops') }}</h1>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12 col-md-6">
        <div class="page-actions page-actions-left">
          <Btn
            v-tooltip="toggleFiltersTooltip"
            :active="shopsFilterVisible"
            :aria-label="toggleFiltersTooltip"
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
      <div class="col-xs-12 col-md-6">
        <div class="pull-right">
          <Paginator
            v-if="shops.length"
            :page="currentPage"
            :total="totalPages"
          />
        </div>
      </div>
    </div>
    <div class="row">
      <transition
        name="slide"
        appear
        @before-enter="toggleFullscreen"
        @after-leave="toggleFullscreen"
      >
        <div
          v-show="shopsFilterVisible"
          class="col-xs-12 col-md-3 col-xlg-2"
        >
          <FilterForm />
        </div>
      </transition>
      <div
        :class="{
          'col-md-9 col-xlg-10': !fullscreen,
        }"
        class="col-xs-12 col-animated"
      >
        <transition-group
          name="fade-list"
          class="flex-row"
          tag="div"
          appear
        >
          <div
            v-for="(shop, index) in shops"
            :key="index"
            class="col-xs-12 col-md-6 fade-list-item"
          >
            <Panel
              :id="`${shop.station.slug}-${shop.slug}`"
              class="shop-list"
            >
              <div
                :style="{
                  'background-image': `url(${shop.storeImage}`,
                }"
                class="panel-bg"
              />
              <div class="row">
                <div class="col-xs-12">
                  <div class="panel-heading">
                    <h2 class="panel-title">
                      <router-link
                        :to="{
                          name: 'shop',
                          params: {
                            station: shop.station.slug,
                            slug: shop.slug,
                          },
                        }"
                        :aria-label="shop.name"
                      >
                        {{ shop.name }}
                      </router-link>
                      <small>
                        {{ shop.station.name }}
                      </small>
                    </h2>
                  </div>
                </div>
              </div>
            </Panel>
          </div>
        </transition-group>
        <EmptyBox v-if="emptyBoxVisible" />
        <Loader
          :loading="loading"
          fixed
        />
      </div>
      <div class="col-xs-12">
        <div class="pull-right">
          <Paginator
            v-if="shops.length"
            :page="currentPage"
            :total="totalPages"
          />
        </div>
      </div>
  </div></section>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import Panel from 'frontend/components/Panel'
import EmptyBox from 'frontend/partials/EmptyBox'
import Hash from 'frontend/mixins/Hash'
import Pagination from 'frontend/mixins/Pagination'
import Filters from 'frontend/mixins/Filters'
import FilterForm from 'frontend/partials/Shops/FilterForm'
import Btn from 'frontend/components/Btn'
import { mapGetters } from 'vuex'

export default {
  components: {
    Loader,
    EmptyBox,
    Panel,
    FilterForm,
    Btn,
  },
  mixins: [I18n, MetaInfo, Hash, Filters, Pagination],
  data() {
    return {
      loading: false,
      shops: [],
      fullscreen: false,
    }
  },
  computed: {
    ...mapGetters([
      'shopsFilterVisible',
      'mobile',
    ]),
    toggleFiltersTooltip() {
      if (this.shopsFilterVisible) {
        return this.t('actions.hideFilter')
      }
      return this.t('actions.showFilter')
    },
    emptyBoxVisible() {
      return !this.loading && this.shops.length === 0
    },
  },
  watch: {
    $route() {
      this.fetch()
    },
  },
  created() {
    this.fetch()
    if (this.mobile) {
      this.$store.commit('setShopsFilterVisible', false)
    }
    this.toggleFullscreen()
  },
  methods: {
    toggleFullscreen() {
      this.fullscreen = !this.shopsFilterVisible
    },
    toggleFilter() {
      this.$store.dispatch('toggleShopsFilter')
    },
    async fetch() {
      this.loading = true
      const response = await this.$api.get('shops', {
        q: this.$route.query.q,
        page: this.$route.query.page,
      })
      this.loading = false
      if (!response.error) {
        this.shops = response.data
        this.scrollToAnchor()
      }
      this.setPages(response.meta)
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.shops'),
    })
  },
}
</script>

<style lang="scss">
  @import './styles/index.scss';
</style>

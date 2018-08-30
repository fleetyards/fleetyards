<template>
  <section class="container compare">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <h1 class="back-button">
              {{ t('headlines.compare.models') }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12">
            <div class="row">
              <div class="hidden-xs hidden-sm col-md-2 text-center"/>
              <div class="col-xs-12 col-md-4">
                <FilterGroup
                  v-model="selectA"
                  :label="t('labels.compare.selectModel')"
                  :name="`model-a`"
                  :search-label="t('actions.findModel')"
                  :fetch="fetchModels"
                  value-attr="slug"
                  paginated
                  searchable
                />
                <router-link
                  v-if="modelA"
                  :to="{ name: 'model', params: { slug: modelA.slug }}"
                  class="thumbnail"
                >
                  <img
                    v-lazy="modelA.storeImage"
                    :key="modelA.storeImage"
                    alt="model Image"
                  >
                </router-link>
              </div>
              <div class="col-xs-12 col-md-4">
                <FilterGroup
                  v-model="selectB"
                  :label="t('labels.compare.selectModel')"
                  :search-label="t('actions.findModel')"
                  :name="`model-b`"
                  :fetch="fetchModels"
                  value-attr="slug"
                  paginated
                  searchable
                />
                <router-link
                  v-if="modelB"
                  :to="{ name: 'model', params: { slug: modelB.slug }}"
                  class="thumbnail"
                >
                  <img
                    v-lazy="modelB.storeImage"
                    :key="modelB.storeImage"
                    alt="model Image"
                  >
                </router-link>
              </div>
            </div>
            <div class="row compare-row visible-xs visible-sm">
              <div class="col-xs-6 col-md-4 text-center">
                <strong v-if="modelA">{{ modelA.name }}</strong>
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <strong v-if="modelB">{{ modelB.name }}</strong>
              </div>
            </div>
            <div class="row compare-row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.productionStatus') }}
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelA">
                  {{ t(`labels.model.productionStatus.${modelA.productionStatus}`) }}
                </span>
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelB">
                  {{ t(`labels.model.productionStatus.${modelB.productionStatus}`) }}
                </span>
              </div>
            </div>
            <div class="row compare-row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.focus') }}
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelA">
                  {{ modelA.focus }}
                </span>
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelB">
                  {{ modelB.focus }}
                </span>
              </div>
            </div>
            <div class="row compare-row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.minCrew') }}
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelA">
                  {{ toNumber(modelA.minCrew, 'people') }}
                </span>
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelB">
                  {{ toNumber(modelB.minCrew, 'people') }}
                </span>
              </div>
            </div>
            <div class="row compare-row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.maxCrew') }}
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelA">
                  {{ toNumber(modelA.maxCrew, 'people') }}
                </span>
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelB">
                  {{ toNumber(modelB.maxCrew, 'people') }}
                </span>
              </div>
            </div>
            <div class="row compare-row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.length') }}
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelA">
                  {{ toNumber(modelA.length, 'distance') }}
                </span>
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelB">
                  {{ toNumber(modelB.length, 'distance') }}
                </span>
              </div>
            </div>
            <div class="row compare-row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.beam') }}
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelA">
                  {{ toNumber(modelA.beam, 'distance') }}
                </span>
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelB">
                  {{ toNumber(modelB.beam, 'distance') }}
                </span>
              </div>
            </div>
            <div class="row compare-row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.height') }}
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelA">
                  {{ toNumber(modelA.height, 'distance') }}
                </span>
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelB">
                  {{ toNumber(modelB.height, 'distance') }}
                </span>
              </div>
            </div>
            <div class="row compare-row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.mass') }}
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelA">
                  {{ toNumber(modelA.mass, 'weight') }}
                </span>
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelB">
                  {{ toNumber(modelB.mass, 'weight') }}
                </span>
              </div>
            </div>
            <div class="row compare-row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.cargo') }}
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelA">
                  {{ toNumber(modelA.cargo, 'cargo') }}
                </span>
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <span v-if="modelB">
                  {{ toNumber(modelB.cargo, 'cargo') }}
                </span>
              </div>
            </div>
            <div
              v-for="category in categories"
              :key="category"
              class="row compare-row"
            >
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t(`labels.hardpoint.categories.${category.toLowerCase()}`) }}
              </div>
              <div class="col-xs-12 col-md-4 text-center">
                <div
                  v-if="modelA"
                  class="well"
                >
                  <HardpointCategory
                    v-if="hardpointsForCategory(category, modelA.hardpoints).length > 0"
                    :category="category"
                    :hardpoints="hardpointsForCategory(category, modelA.hardpoints)"
                    without-title
                  />
                </div>
              </div>
              <div class="col-xs-12 col-md-4 text-center">
                <div
                  v-if="modelB"
                  class="well"
                >
                  <HardpointCategory
                    v-if="hardpointsForCategory(category, modelB.hardpoints).length > 0"
                    :category="category"
                    :hardpoints="hardpointsForCategory(category, modelB.hardpoints)"
                    without-title
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import FilterGroup from 'frontend/components/Form/FilterGroup'
import HardpointIcon from 'frontend/partials/Models/Hardpoints/Icon'
import HardpointCategory from 'frontend/partials/Models/Hardpoints/Category'

export default {
  components: {
    HardpointIcon,
    FilterGroup,
    HardpointCategory,
  },
  mixins: [I18n, MetaInfo],
  data() {
    return {
      selectA: null,
      modelA: null,
      loadingA: false,
      selectB: null,
      modelB: null,
      loadingB: false,
      modelFields: [
        'productionStatus', 'length', 'beam', 'height',
        'mass', 'cargo', 'netCargo', 'crew',
      ],
      categories: ['RSIAvionic', 'RSIModular', 'RSIPropulsion', 'RSIThruster', 'RSIWeapon'],
    }
  },
  computed: {
    sortedModels() {
      const { models } = this
      return models.sort((a, b) => {
        if (a.name < b.name) {
          return -1
        }
        if (a.name > b.name) {
          return 1
        }
        return 0
      })
    },
  },
  watch: {
    selectA(value) {
      let query = JSON.parse(JSON.stringify(this.$route.query))
      if (value) {
        query = Object.assign({}, query, { shipA: value })
        this.setModelA(value)
      } else {
        delete query.shipA
        this.modelA = null
      }
      this.$router.replace({
        name: this.$route.name,
        query,
      })
    },
    selectB(value) {
      let query = JSON.parse(JSON.stringify(this.$route.query))
      if (value) {
        query = Object.assign({}, query, { shipB: value })
        this.setModelB(value)
      } else {
        delete query.shipB
        this.modelB = null
      }
      this.$router.replace({
        name: this.$route.name,
        query,
      })
    },
  },
  created() {
    if (this.$route.query.shipA) {
      this.setModelA(this.$route.query.shipA)
    }
    if (this.$route.query.shipB) {
      this.setModelB(this.$route.query.shipB)
    }
  },
  methods: {
    modularHardpoints(model) {
      return model.hardpoints.filter(item => item.categorySlug === 'modular')
    },
    ordnanceHardpoints(model) {
      return model.hardpoints.filter(item => item.categorySlug === 'ordnance')
    },
    propulsionHardpoints(model) {
      return model.hardpoints.filter(item => item.categorySlug === 'propulsion')
    },
    setModelA(slug) {
      this.loadingA = true
      this.fetchModel(slug, (model) => {
        this.loadingA = false
        this.modelA = model
        if (!this.selectA) {
          this.selectA = model.slug
        }
      })
    },
    setModelB(slug) {
      this.loadingB = true
      this.fetchModel(slug, (model) => {
        this.loadingB = false
        this.modelB = model
        if (!this.selectB) {
          this.selectB = model.slug
        }
      })
    },
    fetchModels({ page, search, missingValue }) {
      const query = {
        q: {},
      }
      if (search) {
        query.q.nameOrSlugCont = search
      } else if (missingValue) {
        query.q.nameOrSlugCont = missingValue
      } else if (page) {
        query.page = page
      }
      return this.$api.get('models', query)
    },
    async fetchModel(slug, callback) {
      const response = await this.$api.get(`models/${slug}`)
      if (!response.error) {
        callback(response.data)
      }
    },
    hardpointsForCategory(category, hardpoints) {
      return hardpoints.filter(hardpoint => hardpoint.class === category)
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.compare.models'),
    })
  },
}
</script>

<style lang="scss" scoped>
  @import 'styles/index.scss';
</style>

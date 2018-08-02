<template>
  <section class="container">
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
                <Multiselect
                  v-model="selectA"
                  :options-limit="100"
                  :placeholder="t('actions.findModel')"
                  :options="models"
                  label="name"
                  track-by="slug"
                  searchable
                />
                <router-link
                  v-if="modelA"
                  :to="{ name: 'model', params: { slug: modelA.slug }}"
                  class="thumbnail"
                >
                  <img
                    v-lazy="modelA.storeImage"
                    alt="model Image"
                  >
                </router-link>
              </div>
              <div class="col-xs-12 col-md-4">
                <Multiselect
                  v-model="selectB"
                  :options-limit="100"
                  :placeholder="t('actions.findModel')"
                  :options="models"
                  label="name"
                  track-by="slug"
                  searchable
                />
                <router-link
                  v-if="modelB"
                  :to="{ name: 'model', params: { slug: modelB.slug }}"
                  class="thumbnail"
                >
                  <img
                    v-lazy="modelB.storeImage"
                    alt="model Image"
                  >
                </router-link>
              </div>
            </div>
            <div class="row visible-xs visible-sm">
              <div
                v-if="modelA"
                class="col-xs-6 col-md-4 text-center"
              >
                <strong>{{ modelA.name }}</strong>
              </div>
              <div
                v-if="modelB"
                class="col-xs-6 col-md-4 text-center"
              >
                <strong>{{ modelB.name }}</strong>
              </div>
            </div>
            <div class="row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.productionStatus') }}
              </div>
              <div
                v-if="modelA"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ t(`labels.model.productionStatus.${modelA.productionStatus}`) }}
              </div>
              <div
                v-if="modelB"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ t(`labels.model.productionStatus.${modelB.productionStatus}`) }}
              </div>
            </div>
            <div class="row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.focus') }}
              </div>
              <div
                v-if="modelA"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ modelA.focus }}
              </div>
              <div
                v-if="modelB"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ modelB.focus }}
              </div>
            </div>
            <div class="row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.minCrew') }}
              </div>
              <div
                v-if="modelA"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ toNumber(modelA.minCrew, 'people') }}
              </div>
              <div
                v-if="modelB"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ toNumber(modelB.minCrew, 'people') }}
              </div>
            </div>
            <div class="row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.maxCrew') }}
              </div>
              <div
                v-if="modelA"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ toNumber(modelA.maxCrew, 'people') }}
              </div>
              <div
                v-if="modelB"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ toNumber(modelB.maxCrew, 'people') }}
              </div>
            </div>
            <div class="row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.length') }}
              </div>
              <div
                v-if="modelA"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ toNumber(modelA.length, 'distance') }}
              </div>
              <div
                v-if="modelB"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ toNumber(modelB.length, 'distance') }}
              </div>
            </div>
            <div class="row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.beam') }}
              </div>
              <div
                v-if="modelA"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ toNumber(modelA.beam, 'distance') }}
              </div>
              <div
                v-if="modelB"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ toNumber(modelB.beam, 'distance') }}
              </div>
            </div>
            <div class="row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.height') }}
              </div>
              <div
                v-if="modelA"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ toNumber(modelA.height, 'distance') }}
              </div>
              <div
                v-if="modelB"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ toNumber(modelB.height, 'distance') }}
              </div>
            </div>
            <div class="row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.mass') }}
              </div>
              <div
                v-if="modelA"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ toNumber(modelA.mass, 'weight') }}
              </div>
              <div
                v-if="modelB"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ toNumber(modelB.mass, 'weight') }}
              </div>
            </div>
            <div class="row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.cargo') }}
              </div>
              <div
                v-if="modelA"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ toNumber(modelA.cargo, 'cargo') }}
              </div>
              <div
                v-if="modelB"
                class="col-xs-6 col-md-4 text-center"
              >
                {{ toNumber(modelB.cargo, 'cargo') }}
              </div>
            </div>
            <div class="row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.propulsion') }}
              </div>
              <div
                v-if="modelA"
                class="col-xs-6 col-md-4 text-center"
              >
                <div class="well">
                  <HardpointIcon
                    v-for="hardpoint in propulsionHardpoints(modelA)"
                    :key="hardpoint.id"
                    :hardpoint="hardpoint"
                    category="propulsion"
                  />
                </div>
              </div>
              <div
                v-if="modelB"
                class="col-xs-6 col-md-4 text-center"
              >
                <div class="well">
                  <HardpointIcon
                    v-for="hardpoint in propulsionHardpoints(modelB)"
                    :key="hardpoint.id"
                    :hardpoint="hardpoint"
                    category="propulsion"
                  />
                </div>
              </div>
            </div>
            <div class="row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.ordnance') }}
              </div>
              <div
                v-if="modelA"
                class="col-xs-6 col-md-4 text-center"
              >
                <div class="well">
                  <HardpointIcon
                    v-for="hardpoint in ordnanceHardpoints(modelA)"
                    :key="hardpoint.id"
                    :hardpoint="hardpoint"
                    category="ordnance"
                  />
                </div>
              </div>
              <div
                v-if="modelB"
                class="col-xs-6 col-md-4 text-center"
              >
                <div class="well">
                  <HardpointIcon
                    v-for="hardpoint in ordnanceHardpoints(modelB)"
                    :key="hardpoint.id"
                    :hardpoint="hardpoint"
                    category="ordnance"
                  />
                </div>
              </div>
            </div>
            <div class="row">
              <div class="col-xs-12 col-md-2 text-right compare-label">
                {{ t('model.modular') }}
              </div>
              <div
                v-if="modelA"
                class="col-xs-6 col-md-4 text-center"
              >
                <div class="well">
                  <HardpointIcon
                    v-for="hardpoint in modularHardpoints(modelA)"
                    :key="hardpoint.id"
                    :hardpoint="hardpoint"
                    category="modular"
                  />
                </div>
              </div>
              <div
                v-if="modelB"
                class="col-xs-6 col-md-4 text-center"
              >
                <div class="well">
                  <HardpointIcon
                    v-for="hardpoint in modularHardpoints(modelB)"
                    :key="hardpoint.id"
                    :hardpoint="hardpoint"
                    category="modular"
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
import HardpointIcon from 'frontend/partials/Models/Hardpoints/Icon'

export default {
  components: {
    HardpointIcon,
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
      models: [],
      modelFields: [
        'productionStatus', 'length', 'beam', 'height',
        'mass', 'cargo', 'netCargo', 'crew',
      ],
    }
  },
  watch: {
    selectA(value) {
      const newQuery = {
        shipA: value.slug,
      }
      this.$router.replace({
        name: this.$route.name,
        query: Object.assign({}, this.$route.query, newQuery),
      })
      this.setModelA(value.slug)
    },
    selectB(value) {
      const newQuery = {
        shipB: value.slug,
      }
      this.$router.replace({
        name: this.$route.name,
        query: Object.assign({}, this.$route.query, newQuery),
      })
      this.setModelB(value.slug)
    },
  },
  created() {
    this.fetchModels()
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
          this.selectA = model
        }
      })
    },
    setModelB(slug) {
      this.loadingB = true
      this.fetchModel(slug, (model) => {
        this.loadingB = false
        this.modelB = model
        if (!this.selectB) {
          this.selectB = model
        }
      })
    },
    fetchModels() {
      this.$api.get('models', {}, (args) => {
        if (!args.error) {
          this.models = args.data
        }
      })
    },
    fetchModel(slug, callback) {
      this.$api.get(`models/${slug}`, {}, (args) => {
        if (!args.error) {
          callback(args.data)
        }
      })
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
  .thumbnail img {
    max-height: 300px;
    min-height: 120px;
  }

  @media (max-width: 767px) {
    .compare-label {
      text-align: center;
    }
  }
</style>

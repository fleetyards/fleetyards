<template>
  <div id="fleetyards-view">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <div class="page-actions">
              <Btn
                v-show="!fleetchart"
                :active="details"
                small
                @click.native="toggleDetails"
              >
                <template v-if="details">{{ t('actions.hideDetails') }}</template>
                <template v-else>{{ t('actions.showDetails') }}</template>
              </Btn>
              <Btn
                small
                @click.native="toggleFleetchart"
              >
                <template v-if="fleetchart">{{ t('actions.hideFleetchart') }}</template>
                <template v-else>{{ t('actions.showFleetchart') }}</template>
              </Btn>
            </div>
          </div>
        </div>
        <div
          v-if="fleetchart && slider"
          class="row"
        >
          <div class="col-xs-12 col-md-4 col-md-offset-4 fleetchart-slider">
            <vue-slider
              ref="slider"
              v-model="scale"
              :min="scaleMin"
              :max="scaleMax"
              :interval="scaleInterval"
              formatter="{value}x"
              tooltip="hover"
            />
          </div>
        </div>
        <div
          v-if="fleetchart"
          class="row"
        >
          <div class="col-xs-12 fleetchart-wrapper">
            <transition-group
              id="fleetchart"
              name="fade-list"
              class="flex-row fleetchart"
              tag="div"
              appear
            >
              <a
                v-for="(model, index) in fleetchartModels"
                :key="`${index}-${model.slug}`"
                :href="`${$root.frontendHost}/ships/${model.slug}`"
                class="fleetchart-item fade-list-item"
                target="_blank"
                rel="noopener"
              >
                <img
                  v-if="model.fleetchartImage"
                  :style="{
                    height: `${model.length * lengthMultiplicator}px`,
                  }"
                  :src="model.fleetchartImage"
                  :alt="model.slug"
                >
                <span v-else>
                  <i class="fal fa-question-circle" />
                  <p>{{ model.name }}</p>
                </span>
                <span class="sr-only">{{ model.name }}</span>
              </a>
            </transition-group>
          </div>
        </div>
        <transition-group
          v-else
          name="fade-list"
          class="flex-row"
          tag="div"
          appear
        >
          <div
            v-for="(model, index) in displayModels"
            :key="`${index}-${model.slug}`"
            class="col-xs-12 col-sm-6 col-lg-4 col-xlg-4 fade-list-item"
          >
            <ModelPanel
              :model="model"
              :details="details"
              :count="count(model.slug)"
            />
          </div>
        </transition-group>
        <Loader
          v-if="loading"
          fixed
        />
      </div>
    </div>
  </div>
</template>

<script>
import ModelPanel from 'embed/partials/Models/Panel'
import Loader from 'frontend/components/Loader'
import Btn from 'frontend/components/Btn'
import I18n from 'frontend/mixins/I18n'
import vueSlider from 'vue-slider-component'

export default {
  name: 'FleetyardsView',
  components: {
    ModelPanel,
    Loader,
    Btn,
    vueSlider,
  },
  mixins: [I18n],
  data() {
    return {
      ships: [],
      models: null,
      details: true,
      grouped: true,
      loading: false,
      fleetchart: false,
      slider: false,
      scale: 1,
      scaleMax: 4,
      scaleMin: 0.1,
      scaleInterval: 0.1,
    }
  },
  computed: {
    toggleDetailsTooltip() {
      if (this.hangarDetails) {
        return this.t('actions.hideDetails')
      }
      return this.t('actions.showDetails')
    },
    ungroupedModels() {
      return this.ships.map(slug => ({
        slug,
        model: this.models.find(model => model.slug === slug),
      }))
        .map((item) => {
          if (!item.model) {
            return {
              name: this.t('labels.unknownModel', { slug: item.slug }),
              slug: item.slug,
              manufacturer: {
                name: this.t('labels.unknown'),
              },
            }
          }
          return item.model
        })
        .sort((a, b) => {
          if (a.name < b.name) {
            return -1
          }
          if (a.name > b.name) {
            return 1
          }
          return 0
        })
    },
    displayModels() {
      if (!this.models) {
        return []
      }
      if (!this.grouped || (!this.fleetchartGrouped && this.fleetchart)) {
        return this.ungroupedModels
      }
      return this.models
    },
    fleetchartModels() {
      const fleetchartModels = this.displayModels.concat()
      return fleetchartModels.sort((a, b) => {
        if (a.length > b.length) {
          return -1
        }
        if (a.length < b.length) {
          return 1
        }
        return 0
      })
    },
    lengthMultiplicator() {
      return this.scale * 4
    },
  },
  mounted() {
    this.ships = this.$root.ships
    this.details = this.$root.details
    this.grouped = this.$root.grouped
    this.fleetchart = this.$root.fleetchart
    this.scale = this.$root.fleetchartScale
    this.fleetchartGrouped = this.$root.fleetchartGrouped
    this.slider = this.$root.fleetchartSlider
    this.fetch()
  },
  methods: {
    toggleDetails() {
      this.details = !this.details
    },
    toggleFleetchart() {
      this.fleetchart = !this.fleetchart
    },
    count(slug) {
      if (!this.grouped) {
        return null
      }
      return this.ships.filter(item => item === slug).length
    },
    fetch() {
      this.loading = true
      this.$api.post('models/embed', {
        models: this.ships.filter((v, i, a) => a.indexOf(v) === i),
      }, (args) => {
        this.loading = false

        if (!args.error) {
          this.models = args.data
        }
      })
    },
  },
}
</script>

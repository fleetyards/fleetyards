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
                :href="`https://www.fleetyards.net/ships/${model.slug}`"
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

export default {
  name: 'FleetyardsView',
  components: {
    ModelPanel,
    Loader,
    Btn,
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
      scale: 1,
      scaleMax: 4,
      scaleMin: 0.5,
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
    displayModels() {
      if (!this.models) {
        return []
      }
      if (this.grouped) {
        return this.models
      }
      return this.ships.map(slug => this.models.find(model => model.slug === slug))
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
    uniq(list) {
      return list.filter((v, i, a) => a.indexOf(v) === i)
    },
    fetch() {
      this.loading = true
      this.$api.post('models/embed', {
        models: this.uniq(this.ships),
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

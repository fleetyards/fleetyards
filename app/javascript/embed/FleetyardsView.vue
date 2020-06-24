<template>
  <div id="fleetyards-view">
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <div class="page-actions">
              <Btn
                v-show="!fleetchart && groupedButton"
                size="small"
                @click.native="toggleGrouping"
              >
                <template v-if="grouping">
                  {{ $t('actions.disableGrouping') }}
                </template>
                <template v-else>
                  {{ $t('actions.enableGrouping') }}
                </template>
              </Btn>
              <Btn
                v-show="fleetchart && groupedButton"
                size="small"
                @click.native="toggleFleetchartGrouping"
              >
                <template v-if="fleetchartGrouping">
                  {{ $t('actions.disableGrouping') }}
                </template>
                <template v-else>
                  {{ $t('actions.enableGrouping') }}
                </template>
              </Btn>
              <Btn
                v-show="!fleetchart"
                :active="details"
                size="small"
                @click.native="toggleDetails"
              >
                <template v-if="details">
                  {{ $t('actions.hideDetails') }}
                </template>
                <template v-else>
                  {{ $t('actions.showDetails') }}
                </template>
              </Btn>
              <Btn size="small" @click.native="toggleFleetchart">
                <template v-if="fleetchart">
                  {{ $t('actions.hideFleetchart') }}
                </template>
                <template v-else>
                  {{ $t('actions.showFleetchart') }}
                </template>
              </Btn>
            </div>
          </div>
        </div>
        <div v-if="fleetchart && slider" class="row justify-content-lg-center">
          <div class="col-12 col-lg-4 fleetchart-slider">
            <FleetchartSlider
              :initial-scale="fleetchartScale"
              @change="updateFleetchartScale"
            />
          </div>
        </div>
        <div v-if="fleetchart" class="row">
          <div class="col-12 fleetchart-wrapper">
            <transition-group
              id="fleetchart"
              name="fade-list"
              class="flex-row fleetchart"
              tag="div"
              appear
            >
              <FleetchartItem
                v-for="(model, index) in fleetchartModels"
                :key="`${index}-${model.slug}`"
                :model="model"
                :scale="fleetchartScale"
              />
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
            class="col-12 col-md-6 col-xl-4 col-xxl-4 fade-list-item"
          >
            <ModelPanel
              :model="model"
              :details="details"
              :count="count(model.slug)"
            />
          </div>
        </transition-group>
        <Loader :loading="loading" fixed />
      </div>
    </div>
  </div>
</template>

<script>
import ModelPanel from 'embed/partials/Models/Panel'
import FleetchartItem from 'embed/partials/Models/FleetchartItem'
import FleetchartSlider from 'frontend/partials/Fleetchart/Slider'
import Loader from 'frontend/components/Loader'
import Btn from 'frontend/components/Btn'
import { mapGetters } from 'vuex'

export default {
  name: 'FleetyardsView',

  components: {
    ModelPanel,
    FleetchartItem,
    Loader,
    Btn,
    FleetchartSlider,
  },

  data() {
    return {
      ships: [],
      users: [],
      vehicles: null,
      models: null,
      loading: false,
      slider: false,
      groupedButton: false,
    }
  },

  computed: {
    ...mapGetters([
      'fleetchartScale',
      'details',
      'grouping',
      'fleetchartGrouping',
      'fleetchart',
    ]),

    ungroupedModels() {
      if (this.ships.length) {
        return this.ships
          .map(slug => ({
            slug,
            model: this.models.find(model => model.slug === slug),
          }))
          .map(this.mapModel)
          .sort(this.sortByName)
      }

      if (this.users) {
        return [...this.models].sort(this.sortByName)
      }

      return []
    },

    displayModels() {
      if (!this.models) {
        return []
      }

      if (!this.grouping || (!this.fleetchartGrouping && this.fleetchart)) {
        return this.ungroupedModels
      }

      if (this.users) {
        return [...this.models].filter((item, pos) => {
          const model = this.models.find(
            modelItem => modelItem.slug === item.slug,
          )
          return this.models.indexOf(model) === pos
        })
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
  },

  watch: {
    ships() {
      this.fetchShips()
    },

    users() {
      this.fetchHangars()
    },

    vehicles() {
      this.models = this.vehicles.map(vehicle => vehicle.model)
    },
  },

  mounted() {
    this.ships = this.$root.ships
    this.users = this.$root.users
    this.slider = this.$root.fleetchartSlider
    this.groupedButton = this.$root.groupedButton

    if (this.users) {
      this.fetchHangars()
    } else {
      this.fetchShips()
    }
  },

  methods: {
    sortByName(a, b) {
      if (a.name < b.name) {
        return -1
      }
      if (a.name > b.name) {
        return 1
      }
      return 0
    },

    mapModel(item) {
      if (!item.model) {
        return {
          name: this.$t('labels.unknownModel', { slug: item.slug }),
          slug: item.slug,
          manufacturer: {
            name: this.$t('labels.unknown'),
          },
        }
      }
      return item.model
    },

    updateShips(ships) {
      this.ships = ships
    },

    updateUsers(users) {
      this.users = users
    },

    updateFleetchartScale(value) {
      this.$store.commit('setFleetchartScale', value)
    },

    toggleDetails() {
      this.$store.commit('toggleDetails')
    },

    toggleFleetchart() {
      this.$store.commit('toggleFleetchart')
    },

    toggleGrouping() {
      this.$store.commit('toggleGrouping')
    },

    toggleFleetchartGrouping() {
      this.$store.commit('toggleFleetchartGrouping')
    },

    count(slug) {
      if (!this.grouping) {
        return null
      }

      if (this.users) {
        return this.models.filter(model => model.slug === slug).length
      }

      return this.ships.filter(item => item === slug).length
    },

    async fetchShips() {
      this.loading = true
      const response = await this.$api.get('models/embed', {
        models: this.ships.filter((v, i, a) => a.indexOf(v) === i),
      })
      this.loading = false

      if (!response.error) {
        this.models = response.data
      }
    },

    async fetchHangars() {
      this.loading = true

      const response = await this.$api.get('vehicles/embed', {
        usernames: this.users,
      })

      this.loading = false

      if (!response.error) {
        this.vehicles = response.data
      }
    },
  },
}
</script>

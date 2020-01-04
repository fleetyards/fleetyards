<template>
  <section
    :class="{
      'scrolled-top': scrolledTop,
      'scrolled-left': scrolledLeft,
    }"
    class="container compare-models"
  >
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <BreadCrumbs :crumbs="crumbs" />
            <br>
            <h1 class="sr-only">
              {{ $t('headlines.compare.models') }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12">
            <div class="row compare-row compare-row-headline">
              <div class="col-xs-12 compare-row-label">
                <FilterGroup
                  v-model="newModel"
                  v-tooltip="disabledTooltip"
                  :label="$t('labels.compare.addModel')"
                  name="new-model"
                  :search-label="$t('actions.findModel')"
                  :fetch="fetchModels"
                  value-attr="slug"
                  :disabled="selectDisabled"
                  paginated
                  searchable
                  @input="add"
                />
                <Btn
                  :href="erkulUrl"
                  block
                  class="erkul-link"
                >
                  <i />
                  {{ $t('labels.erkul.link' ) }}
                </Btn>
              </div>
              <div
                v-for="model in sortedModels"
                :key="`${model.slug}-image`"
                class="col-xs-12 compare-row-item"
              >
                <div class="compare-image">
                  <router-link
                    :key="model.storeImage"
                    v-lazy:background-image="model.storeImage"
                    :to="{ name: 'model', params: { slug: model.slug }}"
                    :aria-label="model.name"
                    class="lazy"
                  />
                  <div
                    v-tooltip="$t('labels.compare.removeModel')"
                    class="remove-model"
                    @click="remove(model)"
                  >
                    <i class="fal fa-times" />
                  </div>
                </div>
                <div
                  :style="{
                    top: `${scrolledTopOffset - 81}px`,
                  }"
                  class="text-center compare-title"
                >
                  <strong>{{ model.name }}</strong>
                </div>
              </div>
            </div>

            <div
              v-if="!sortedModels.length"
              class="row compare-row"
            >
              <div class="col-xs-12">
                <Box
                  class="info"
                  large
                >
                  <h1>{{ $t('headlines.compare.models') }}</h1>
                  <p>{{ $t('texts.compare.models.info') }}</p>
                </Box>
              </div>
            </div>
            <div class="compare-wrapper">
              <BaseRows
                :models="sortedModels"
                :scroll-left="scrolledLeftOffset"
              />

              <CrewRows
                :models="sortedModels"
                :scroll-left="scrolledLeftOffset"
              />

              <SpeedRows
                :models="sortedModels"
                :scroll-left="scrolledLeftOffset"
              />

              <CategoryRows
                :models="sortedModels"
                :scroll-left="scrolledLeftOffset"
              />

              <Legend :models="sortedModels" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import FilterGroup from 'frontend/components/Form/FilterGroup'
import Box from 'frontend/components/Box'
import Btn from 'frontend/components/Btn'
import BreadCrumbs from 'frontend/components/BreadCrumbs'
import BaseRows from 'frontend/partials/Compare/Models/Base'
import CrewRows from 'frontend/partials/Compare/Models/Crew'
import SpeedRows from 'frontend/partials/Compare/Models/Speed'
import CategoryRows from 'frontend/partials/Compare/Models/Categories'
import Legend from 'frontend/partials/Compare/Models/Legend'

export default {
  name: 'ModelsCompare',

  components: {
    FilterGroup,
    Box,
    Btn,
    BreadCrumbs,
    BaseRows,
    CrewRows,
    SpeedRows,
    CategoryRows,
    Legend,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    const query = JSON.parse(JSON.stringify(this.$route.query || {}))

    return {
      scrolledTop: false,
      scrolledLeft: false,
      scrolledTopOffset: 0,
      scrolledLeftOffset: 0,
      newModel: null,
      form: {
        models: query.models || [],
      },
      models: [],
    }
  },

  computed: {
    erkulUrl() {
      return 'https://www.erkul.games/calculator'
    },

    sortedModels() {
      const models = JSON.parse(JSON.stringify(this.models))

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

    selectDisabled() {
      return this.models.length > 7
    },

    disabledTooltip() {
      if (this.selectDisabled) {
        return this.$t('labels.compare.enough')
      }

      return null
    },

    crumbs() {
      return [{
        to: {
          name: 'models',
        },
        label: this.$t('nav.models'),
      }]
    },
  },

  watch: {
    form: {
      handler() {
        this.update()
      },
      deep: true,
    },
  },

  created () {
    window.addEventListener('scroll', this.handleScroll)
  },

  destroyed () {
    window.removeEventListener('scroll', this.handleScroll)
  },

  mounted() {
    this.form.models.forEach(async (slug) => {
      const model = await this.fetchModel(slug)
      this.models.push(model)
    })
  },

  methods: {
    handleScroll() {
      this.scrolledTop = document.documentElement.scrollTop > 261
      this.scrolledLeft = document.documentElement.scrollLeft > 200
      this.scrolledTopOffset = document.documentElement.scrollTop
      this.scrolledLeftOffset = this.scrolledLeft ? document.documentElement.scrollLeft : 0
    },

    update() {
      this.$router.replace({
        name: this.$route.name,
        query: {
          models: this.form.models,
        },
      })
    },

    async add() {
      if (this.newModel && !this.form.models.includes(this.newModel)) {
        const model = await this.fetchModel(this.newModel)
        this.models.push(model)
        this.form.models.push(this.newModel)
      }
      this.newModel = null
    },

    remove(model) {
      if (this.form.models.includes(model.slug)) {
        const index = this.form.models.indexOf(model.slug)
        this.form.models.splice(index, 1)
      }

      if (this.models.findIndex((item) => item.slug === model.slug) >= 0) {
        const index = this.models.findIndex((item) => item.slug === model.slug)
        this.models.splice(index, 1)
      }
    },

    fetchModels({ page, search, missingValue }) {
      const query = {
        q: {},
      }

      if (search) {
        query.q.nameCont = search
      } else if (missingValue) {
        query.q.nameCont = missingValue
      } else if (page) {
        query.page = page
      }

      return this.$api.get('models', query)
    },

    async fetchModel(slug) {
      const response = await this.$api.get(`models/${slug}`, {
        withoutImages: true,
        withoutVideos: true,
      })

      if (!response.error) {
        return response.data
      }

      return null
    },
  },
}
</script>

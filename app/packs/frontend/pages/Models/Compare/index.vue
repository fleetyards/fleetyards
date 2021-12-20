<template>
  <section
    :class="{
      'nav-slim': navSlim,
    }"
    class="container compare-models"
  >
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <BreadCrumbs :crumbs="crumbs" />
            <br />
            <h1 class="sr-only">
              {{ $t('headlines.compare.models') }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-12">
            <div class="row compare-row compare-row-headline">
              <div class="col-12 compare-row-label">
                <CollectionFilterGroup
                  v-model="newModel"
                  v-tooltip="disabledTooltip"
                  name="new-model"
                  :search-label="$t('actions.findModel')"
                  :collection="modelsCollection"
                  value-attr="slug"
                  translation-key="compare.addModel"
                  :disabled="selectDisabled"
                  :paginated="true"
                  :searchable="true"
                  :return-object="true"
                  :no-label="true"
                  @input="add"
                />
                <Btn :href="erkulUrl" :block="true" class="erkul-link">
                  <i />
                  {{ $t('labels.erkul.link') }}
                </Btn>
              </div>
              <div
                v-for="model in sortedModels"
                :key="`${model.slug}-image`"
                class="col-12 compare-row-item"
              >
                <div class="compare-image">
                  <router-link
                    :key="model.storeImage"
                    v-lazy:background-image="model.storeImage"
                    :to="{ name: 'model', params: { slug: model.slug } }"
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
              </div>
            </div>
            <div class="row compare-row compare-row-headline sticky">
              <div class="col-12 compare-row-label" />
              <div
                v-for="model in sortedModels"
                :key="`${model.slug}-title`"
                class="col-12 compare-row-item"
              >
                <div class="text-center compare-title">
                  <strong>{{ model.name }}</strong>
                </div>
              </div>
            </div>

            <div v-if="!sortedModels.length" class="row compare-row">
              <div class="col-12">
                <Box class="info" :large="true">
                  <h1>{{ $t('headlines.compare.models') }}</h1>
                  <p>{{ $t('texts.compare.models.info') }}</p>
                </Box>
              </div>
            </div>
            <div class="compare-wrapper">
              <TopViewRows :models="sortedModels" />
              <BaseRows :models="sortedModels" />
              <CrewRows :models="sortedModels" />
              <SpeedRows :models="sortedModels" />
              <HardpointRows :models="sortedModels" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import MetaInfo from 'frontend/mixins/MetaInfo'
import CollectionFilterGroup from 'frontend/core/components/Form/CollectionFilterGroup'
import Box from 'frontend/core/components/Box'
import Btn from 'frontend/core/components/Btn'
import BreadCrumbs from 'frontend/core/components/BreadCrumbs'
import TopViewRows from 'frontend/components/Compare/Models/TopView'
import BaseRows from 'frontend/components/Compare/Models/Base'
import CrewRows from 'frontend/components/Compare/Models/Crew'
import SpeedRows from 'frontend/components/Compare/Models/Speed'
import HardpointRows from 'frontend/components/Compare/Models/Hardpoints'
import modelsCollection from 'frontend/api/collections/Models'
import modelHardpointsCollection from 'frontend/api/collections/ModelHardpoints'

@Component<ModelsCompare>({
  components: {
    CollectionFilterGroup,
    Box,
    Btn,
    BreadCrumbs,
    TopViewRows,
    BaseRows,
    CrewRows,
    SpeedRows,
    HardpointRows,
  },
  mixins: [MetaInfo],
})
export default class ModelsCompare extends Vue {
  @Getter('navSlim', { namespace: 'app' }) navSlim: boolean

  modelsCollection: ModelsCollection = modelsCollection

  newModel: Model | null = null

  models: Model[] = []

  form = {}

  get erkulUrl() {
    return 'https://www.erkul.games/calculator'
  }

  get sortedModels() {
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
  }

  get selectDisabled() {
    return this.models.length > 7
  }

  get disabledTooltip() {
    if (this.selectDisabled) {
      return this.$t('labels.compare.enough')
    }

    return null
  }

  get crumbs() {
    return [
      {
        to: {
          name: 'models',
        },
        label: this.$t('nav.models.index'),
      },
    ]
  }

  @Watch('form', { deep: true })
  onFormChange() {
    this.update()
  }

  mounted() {
    this.setupForm()
    this.form.models.forEach(async (slug) => {
      const model = await this.fetchModel(slug)
      this.models.push(model)
    })
  }

  setupForm() {
    const query = JSON.parse(JSON.stringify(this.$route.query || {}))
    this.form = {
      models: query.models || [],
    }
  }

  update() {
    this.$router
      .replace({
        name: this.$route.name,
        query: {
          models: this.form.models,
        },
      })
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch(() => {})
  }

  async add() {
    if (this.newModel && !this.form.models.includes(this.newModel.slug)) {
      const model = await this.fetchModel(this.newModel.slug)
      this.models.push(model)
      this.form.models.push(this.newModel.slug)
    }
    this.newModel = null
  }

  remove(model) {
    if (this.form.models.includes(model.slug)) {
      const index = this.form.models.indexOf(model.slug)
      this.form.models.splice(index, 1)
    }

    if (this.models.findIndex((item) => item.slug === model.slug) >= 0) {
      const index = this.models.findIndex((item) => item.slug === model.slug)
      this.models.splice(index, 1)
    }
  }

  async fetchModel(slug) {
    const model = await modelsCollection.findBySlug(slug)

    const hardpoints = await modelHardpointsCollection.findAllByModel(slug)

    return {
      ...model,
      hardpoints,
    }
  }
}
</script>

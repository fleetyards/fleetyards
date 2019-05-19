<template>
  <section class="container compare">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <h1 class="sr-only">
              {{ $t('headlines.compare.models') }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12">
            <div class="row">
              <div class="col-xs-12 col-ms-6 col-md-4 col-md-offset-2">
                <FilterGroup
                  v-model="selectA"
                  :label="$t('labels.compare.selectModel')"
                  :name="`model-a`"
                  :search-label="$t('actions.findModel')"
                  :fetch="fetchModels"
                  value-attr="slug"
                  paginated
                  searchable
                />
                <div
                  v-if="modelA"
                  class="compare-image"
                >
                  <router-link
                    :key="modelA.storeImage"
                    v-lazy:background-image="modelA.storeImage"
                    :to="{ name: 'model', params: { slug: modelA.slug }}"
                    :aria-label="modelA.name"
                    class="lazy"
                  />
                </div>
              </div>
              <div class="col-xs-12 col-ms-6 col-md-4">
                <FilterGroup
                  v-model="selectB"
                  :label="$t('labels.compare.selectModel')"
                  :search-label="$t('actions.findModel')"
                  :name="`model-b`"
                  :fetch="fetchModels"
                  value-attr="slug"
                  paginated
                  searchable
                />
                <div
                  v-if="modelB"
                  class="compare-image"
                >
                  <router-link
                    :key="modelB.storeImage"
                    v-lazy:background-image="modelB.storeImage"
                    :to="{ name: 'model', params: { slug: modelB.slug }}"
                    :aria-label="modelB.name"
                    class="lazy"
                  />
                </div>
              </div>
            </div>

            <div class="row compare-row visible-xs visible-sm">
              <div class="col-xs-6 col-md-4 text-center">
                <strong v-if="modelA">
                  {{ modelA.name }}
                </strong>
              </div>
              <div class="col-xs-6 col-md-4 text-center">
                <strong v-if="modelB">
                  {{ modelB.name }}
                </strong>
              </div>
            </div>

            <div
              v-if="!modelA && !modelB"
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
            <div class="row compare-row compare-section">
              <div class="col-xs-12 col-md-2">
                <div
                  :class="{
                    active: baseVisible
                  }"
                  class="text-right metrics-title"
                  @click="toggle('base')"
                >
                  {{ $t('labels.metrics.base') }}
                  <i class="fa fa-chevron-right" />
                </div>
              </div>
              <div class="col-xs-6 col-md-4" />
              <div class="col-xs-6 col-md-4" />
            </div>
            <b-collapse
              id="base"
              :visible="baseVisible"
            >
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.manufacturer') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                    v-html="modelA.manufacturer.name"
                  />
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                    v-html="modelB.manufacturer.name"
                  />
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.productionStatus') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $t(`labels.model.productionStatus.${modelA.productionStatus}`) }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $t(`labels.model.productionStatus.${modelB.productionStatus}`) }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.focus') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ modelA.focus }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ modelB.focus }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.classification') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ modelA.classificationLabel }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ modelB.classificationLabel }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.size') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ modelA.sizeLabel }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ modelB.sizeLabel }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.length') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.length, 'distance') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.length, 'distance') }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.beam') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.beam, 'distance') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.beam, 'distance') }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.height') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.height, 'distance') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.height, 'distance') }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.mass') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.mass, 'weight') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.mass, 'weight') }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.cargo') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.cargo, 'cargo') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.cargo, 'cargo') }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.price') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toDollar(modelA.price) }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toDollar(modelB.price) }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.pledgePrice') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toDollar(modelA.lastPledgePrice) }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toDollar(modelB.lastPledgePrice) }}
                  </span>
                </div>
              </div>
            </b-collapse>

            <div class="row compare-row compare-section">
              <div class="col-xs-12 col-md-2">
                <div
                  :class="{
                    active: crewVisible
                  }"
                  class="text-right metrics-title"
                  @click="toggle('crew')"
                >
                  {{ $t('labels.metrics.crew') }}
                  <i class="fa fa-chevron-right" />
                </div>
              </div>
              <div class="col-xs-6 col-md-4" />
              <div class="col-xs-6 col-md-4" />
            </div>
            <b-collapse
              id="crew"
              :visible="crewVisible"
            >
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.minCrew') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.minCrew, 'people') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.minCrew, 'people') }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.maxCrew') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.maxCrew, 'people') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.maxCrew, 'people') }}
                  </span>
                </div>
              </div>
            </b-collapse>

            <div class="row compare-row compare-section">
              <div class="col-xs-12 col-md-2">
                <div
                  :class="{
                    active: speedVisible
                  }"
                  class="text-right metrics-title"
                  @click="toggle('speed')"
                >
                  {{ $t('labels.metrics.speed') }}
                  <i class="fa fa-chevron-right" />
                </div>
              </div>
              <div class="col-xs-6 col-md-4" />
              <div class="col-xs-6 col-md-4" />
            </div>
            <b-collapse
              id="speed"
              :visible="speedVisible"
            >
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.scmSpeed') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.scmSpeed, 'speed') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.scmSpeed, 'speed') }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.afterburnerSpeed') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.afterburnerSpeed, 'speed') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.afterburnerSpeed, 'speed') }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.groundSpeed') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.groundSpeed, 'speed') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.groundSpeed, 'speed') }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.afterburnerGroundSpeed') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.afterburnerGroundSpeed, 'speed') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.afterburnerGroundSpeed, 'speed') }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.pitchMax') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.pitchMax, 'rotation') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.pitchMax, 'rotation') }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.yawMax') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.yawMax, 'rotation') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.yawMax, 'rotation') }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.rollMax') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.rollMax, 'rotation') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.rollMax, 'rotation') }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.xaxisAcceleration') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.xaxisAcceleration, 'speed') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.xaxisAcceleration, 'speed') }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.yaxisAcceleration') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.yaxisAcceleration, 'speed') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.yaxisAcceleration, 'speed') }}
                  </span>
                </div>
              </div>
              <div
                v-if="modelA || modelB"
                class="row compare-row"
              >
                <div class="col-xs-12 col-md-2 text-right metrics-label">
                  {{ $t('model.zaxisAcceleration') }}
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelA"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelA.zaxisAcceleration, 'speed') }}
                  </span>
                </div>
                <div class="col-xs-6 col-md-4 text-center">
                  <span
                    v-if="modelB"
                    class="metrics-value"
                  >
                    {{ $toNumber(modelB.zaxisAcceleration, 'speed') }}
                  </span>
                </div>
              </div>
            </b-collapse>

            <div
              v-for="category in categories"
              :key="category"
            >
              <div class="row compare-row compare-section">
                <div class="col-xs-12 col-md-2">
                  <div
                    :class="{
                      active: isVisible(category.toLowerCase())
                    }"
                    class="text-right metrics-title"
                    @click="toggle(category.toLowerCase())"
                  >
                    {{ $t(`labels.hardpoint.categories.${category.toLowerCase()}`) }}
                    <i class="fa fa-chevron-right" />
                  </div>
                </div>
                <div class="col-xs-6 col-md-4" />
                <div class="col-xs-6 col-md-4" />
              </div>
              <b-collapse
                :id="category"
                :visible="isVisible(category.toLowerCase())"
              >
                <div
                  v-if="modelA || modelB"
                  class="row compare-row"
                >
                  <div class="col-xs-12 col-ms-12 col-md-2" />
                  <div class="col-xs-12 col-ms-6 col-md-4 text-center">
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
                  <div class="col-xs-12 col-ms-6 col-md-4 text-center">
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
              </b-collapse>
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
import HardpointCategory from 'frontend/partials/Models/Hardpoints/Category'
import Box from 'frontend/components/Box'

export default {
  components: {
    FilterGroup,
    HardpointCategory,
    Box,
  },
  mixins: [MetaInfo],
  data() {
    return {
      selectA: null,
      modelA: null,
      loadingA: false,
      selectB: null,
      modelB: null,
      loadingB: false,
      baseVisible: true,
      crewVisible: true,
      speedVisible: true,
      rsiavionicVisible: true,
      rsimodularVisible: true,
      rsipropulsionVisible: true,
      rsithrusterVisible: true,
      rsiweaponVisible: true,
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
        query.q.nameCont = search
      } else if (missingValue) {
        query.q.nameCont = missingValue
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
    isVisible(type) {
      return this[`${type}Visible`]
    },
    toggle(type) {
      this[`${type}Visible`] = !this[`${type}Visible`]
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.$t('title.compare.models'),
    })
  },
}
</script>

<style lang="scss" scoped>
  @import 'styles/index.scss';
</style>

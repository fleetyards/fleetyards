<template>
  <section class="container stats">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <h1 class="sr-only">
              {{ $t('headlines.stats') }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-6">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ $t('labels.stats.modelsByClassification') }}
                </h2>
              </div>
              <Chart
                key="models-by-classification"
                :load-data="loadModelsByClassification"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
          <div class="col-xs-12 col-md-6">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ $t('labels.stats.modelsBySize') }}
                </h2>
              </div>
              <Chart
                key="models-by-size"
                :load-data="loadModelsBySize"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-4">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ $t('labels.stats.modelsByProductionStatus') }}
                </h2>
              </div>
              <Chart
                key="models-by-production-status"
                :load-data="loadModelsByProductionStatus"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
          <div class="col-xs-12 col-md-8">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ $t('labels.stats.modelsPerMonth') }}
                </h2>
              </div>
              <Chart
                key="models-per-month"
                :load-data="loadModelsPerMonth"
                tooltip-type="ship"
                type="column"
              />
            </Panel>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-6">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ $t('labels.stats.modelsByManufacturer') }}
                </h2>
              </div>
              <Chart
                key="models-by-manufacturer"
                :load-data="loadModelsByManufacturer"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Chart from 'frontend/components/Chart'
import Panel from 'frontend/components/Panel'

export default {
  name: 'Stats',

  components: {
    Chart,
    Panel,
  },

  mixins: [
    MetaInfo,
  ],

  methods: {
    async loadModelsByClassification() {
      const response = await this.$api.get('stats/models-by-classification')
      if (!response.error) {
        return response.data
      }
      return []
    },

    async loadModelsBySize() {
      const response = await this.$api.get('stats/models-by-size')
      if (!response.error) {
        return response.data
      }
      return []
    },

    async loadModelsPerMonth() {
      const response = await this.$api.get('stats/models-per-month')
      if (!response.error) {
        return response.data
      }
      return []
    },

    async loadModelsByManufacturer() {
      const response = await this.$api.get('stats/models-by-manufacturer')
      if (!response.error) {
        return response.data
      }
      return []
    },

    async loadModelsByProductionStatus() {
      const response = await this.$api.get('stats/models-by-production-status')
      if (!response.error) {
        return response.data
      }
      return []
    },
  },
}
</script>

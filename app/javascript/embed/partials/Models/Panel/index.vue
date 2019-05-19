<template>
  <div>
    <Panel
      v-if="model"
      :id="model.slug"
    >
      <div class="panel-heading">
        <h2 class="panel-title">
          <a
            :href="url"
            target="_blank"
            rel="noopener"
          >
            {{ countLabel }}{{ model.name }}
          </a>
          <br>
          <small v-html="model.manufacturer.name" />
        </h2>
      </div>
      <div class="panel-image text-center">
        <a
          v-lazy:background-image="model.storeImage"
          :href="url"
          target="_blank"
          rel="noopener"
          class="lazy"
        />
      </div>
      <div
        v-if="details"
        class="production-status"
      >
        <strong class="text-uppercase">
          <template v-if="model.productionStatus">
            {{ $t(`labels.model.productionStatus.${model.productionStatus}`) }}
          </template>
          <template v-else>
            {{ $t(`labels.not-available`) }}
          </template>
        </strong>
      </div>
      <ul
        v-if="details"
        class="list-group"
      >
        <li class="list-group-item">
          <ModelTopMetrics :model="model" />
        </li>
        <li class="list-group-item">
          <ModelBaseMetrics :model="model" />
        </li>
      </ul>
    </Panel>
  </div>
</template>

<script>
import Panel from 'frontend/components/Panel'
import ModelTopMetrics from 'frontend/partials/Models/TopMetrics'
import ModelBaseMetrics from 'frontend/partials/Models/BaseMetrics'

export default {
  components: {
    Panel,
    ModelTopMetrics,
    ModelBaseMetrics,
  },
  props: {
    model: {
      type: Object,
      required: true,
    },
    details: {
      type: Boolean,
      default: false,
    },
    count: {
      type: Number,
      default: null,
    },
  },
  computed: {
    url() {
      return `${window.FRONTEND_ENDPOINT}/ships/${this.model.slug}`
    },
    countLabel() {
      if (!this.count) {
        return ''
      }
      return `${this.count}x `
    },
  },
}
</script>

<style lang="scss" scoped>
  @import './styles/index';
</style>

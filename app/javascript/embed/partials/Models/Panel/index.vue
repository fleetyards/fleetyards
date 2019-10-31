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
        <LazyImage
          :href="url"
          target="_blank"
          rel="noopener"
          :aria-label="model.name"
          :src="model.storeImageMedium"
          :alt="model.name"
          class="image"
        >
          <div
            v-show="model.onSale"
            v-tooltip="$t('labels.model.onSale')"
            class="on-sale"
          >
            <i class="fal fa-dollar-sign" />$
          </div>
        </LazyImage>
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
      <ModelTopMetrics :model="model" />
      <hr>
      <ModelBaseMetrics :model="model" />
    </Panel>
  </div>
</template>

<script>
import Panel from 'frontend/components/Panel'
import ModelTopMetrics from 'frontend/partials/Models/TopMetrics'
import ModelBaseMetrics from 'frontend/partials/Models/BaseMetrics'
import LazyImage from 'frontend/components/LazyImage'

export default {
  components: {
    Panel,
    ModelTopMetrics,
    ModelBaseMetrics,
    LazyImage,
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
  @import 'index';
</style>

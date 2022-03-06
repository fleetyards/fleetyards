<template>
  <div>
    <Panel v-if="model" :id="model.slug">
      <div class="panel-heading">
        <h2 class="panel-title">
          <a :href="url" target="_blank" rel="noopener">
            {{ countLabel }}{{ model.name }}
          </a>
          <br />
          <small
            v-if="model.manufacturer"
            class="text-muted"
            v-html="model.manufacturer.name"
          />
        </h2>
      </div>
      <div
        :class="{
          'no-details': !details,
        }"
        class="panel-image text-center"
      >
        <LazyImage
          v-if="model.storeImageMedium"
          :href="url"
          target="_blank"
          rel="noopener"
          :aria-label="model.name"
          :src="model.storeImageMedium"
          :alt="model.name"
          class="image"
        />
      </div>
      <PanelDetails
        :key="`details-${model.slug}-${uuid}-wrapper`"
        :visible="details"
      >
        <div class="production-status">
          <strong class="text-uppercase">
            <template v-if="model.productionStatus">
              {{
                $t(`labels.model.productionStatus.${model.productionStatus}`)
              }}
            </template>
            <template v-else>
              {{ $t(`labels.not-available`) }}
            </template>
          </strong>
        </div>
        <ModelTopMetrics :model="model" padding />
        <hr class="dark slim-spacer" />
        <ModelBaseMetrics :model="model" padding />
      </PanelDetails>
    </Panel>
  </div>
</template>

<script>
import Panel from '@/embed/components/Panel/index.vue'
import PanelDetails from '@/embed/components/Panel/PanelDetails/index.vue'
import ModelTopMetrics from '@/embed/partials/Models/TopMetrics/index.vue'
import ModelBaseMetrics from '@/embed/partials/Models/BaseMetrics/index.vue'
import LazyImage from '@/embed/components/LazyImage/index.vue'

export default {
  name: 'ModelsPanel',

  components: {
    LazyImage,
    ModelBaseMetrics,
    ModelTopMetrics,
    Panel,
    PanelDetails,
  },

  props: {
    count: {
      default: null,
      type: Number,
    },

    details: {
      type: Boolean,
      default: false,
    },

    model: {
      type: Object,
      required: true,
    },
  },

  computed: {
    countLabel() {
      if (!this.count) {
        return ''
      }
      return `${this.count}x `
    },

    url() {
      return `${window.FRONTEND_ENDPOINT}/ships/${this.model.slug}`
    },

    uuid() {
      return this._uid
    },
  },
}
</script>

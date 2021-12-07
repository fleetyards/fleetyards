<template>
  <div>
    <Panel
      v-if="model"
      :id="model.slug"
      class="model-panel"
      :class="`model-panel-${model.slug}`"
    >
      <div class="panel-heading">
        <h2 class="panel-title">
          <router-link
            :to="{
              name: 'model',
              params: {
                slug: model.slug,
              },
            }"
          >
            <span>{{ model.name }}</span>
          </router-link>

          <br />

          <small>
            <router-link
              :to="{
                query: {
                  q: filterManufacturerQuery(model.manufacturer.slug),
                },
              }"
              v-html="model.manufacturer.name"
            />
          </small>

          <AddToHangar
            :model="model"
            class="panel-add-to-hangar-button"
            variant="panel"
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
          :to="{ name: 'model', params: { slug: model.slug } }"
          :aria-label="model.name"
          :src="storeImage"
          :alt="model.name"
          class="image"
        >
          <div
            v-show="model.onSale"
            v-tooltip="$t('labels.model.onSale')"
            class="on-sale"
          >
            <i class="fal fa-dollar-sign" />
          </div>
        </LazyImage>
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
        <ModelPanelMetrics :model="model" />
      </PanelDetails>
    </Panel>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Panel from 'frontend/core/components/Panel'
import PanelDetails from 'frontend/core/components/Panel/PanelDetails'
import LazyImage from 'frontend/core/components/LazyImage'
import AddToHangar from 'frontend/components/Models/AddToHangar'
import ModelPanelMetrics from 'frontend/components/Models/PanelMetrics'

@Component<ModelPanel>({
  components: {
    Panel,
    PanelDetails,
    LazyImage,
    AddToHangar,
    ModelPanelMetrics,
  },
})
export default class ModelPanel extends Vue {
  @Prop({ required: true }) model: Model

  @Prop({ default: false }) details: boolean

  get uuid() {
    return this._uid
  }

  get storeImage() {
    return this.model.storeImageMedium
  }

  filterManufacturerQuery(manufacturer) {
    return { manufacturerIn: [manufacturer] }
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>

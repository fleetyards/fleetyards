<template>
  <div class="row">
    <div class="col-12 paints">
      <hr v-if="paints.length" />
      <h2 v-if="paints.length" class="text-uppercase">
        {{ $t('labels.model.paints') }}
      </h2>
      <transition-group
        v-if="paints.length"
        name="fade-list"
        class="row"
        tag="div"
        appear
      >
        <div
          v-for="paint in paints"
          :key="`paint-${paint.slug}`"
          class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
        >
          <TeaserPanel :item="paint" :fullscreen="true" />
        </div>
      </transition-group>
      <Loader :loading="loading" :fixed="true" />
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import Loader from 'frontend/core/components/Loader'
import TeaserPanel from 'frontend/core/components/TeaserPanel'
import modelPaintsCollection from 'frontend/api/collections/ModelPaints'

@Component<ModelPaintList>({
  components: {
    Loader,
    TeaserPanel,
  },
})
export default class ModelPaintList extends Vue {
  get paints() {
    return this.collection.records
  }

  @Prop({ required: true }) model!: Model

  collection: ModelPaintsCollection = modelPaintsCollection

  loading: boolean = false

  @Watch('model')
  onModelChange() {
    this.fetch()
  }

  mounted() {
    this.fetch()
  }

  async fetch() {
    if (!this.model) {
      return
    }

    this.loading = true

    await this.collection.findAllByModel(this.model.slug)

    this.loading = false
  }
}
</script>

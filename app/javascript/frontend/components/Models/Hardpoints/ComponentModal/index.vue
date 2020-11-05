<template>
  <Modal :title="(component && component.name) || ''">
    <div v-if="component" class="col-12 metrics-block">
      <div class="row">
        <div class="col-6">
          <div class="metrics-label">{{ $t('component.size') }}:</div>
          <div class="metrics-value">
            {{ component.size }}
          </div>
          <div class="metrics-label">{{ $t('component.manufacturer') }}:</div>
          <div class="metrics-value" v-html="component.manufacturer.name" />
        </div>
        <div v-if="hardpoint.type === 'missiles'" class="col-6">
          <div class="metrics-label">
            {{ $t('labels.hardpoint.rackSize') }}:
          </div>
          <div class="metrics-value">
            {{ hardpoint.size }}
          </div>
        </div>
        <div v-if="hardpoint.details" class="col-6">
          <div class="metrics-label">{{ $t('labels.hardpoint.details') }}:</div>
          <div class="metrics-value">
            {{ hardpoint.details }}
          </div>
        </div>
      </div>
    </div>
    <div class="clearfix" />
  </Modal>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Modal from 'frontend/core/components/AppModal/Modal'

@Component<Support>({
  components: {
    Modal,
  },
})
export default class Support extends Vue {
  @Prop({ required: true }) hardpoint: Hardpoint

  get component() {
    return this.hardpoint.component
  }
}
</script>

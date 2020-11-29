<template>
  <div>
    <div v-if="erkulUrl" class="d-flex justify-content-center">
      <Btn :href="erkulUrl" :mobile-block="true" class="erkul-link">
        <small>{{ $t('labels.erkul.prefix') }}</small>
        <i />
        {{ $t('labels.erkul.link') }}
      </Btn>
    </div>
    <div class="row">
      <div
        v-for="category in ['RSIAvionic', 'RSIModular']"
        :key="category"
        class="col-12 col-lg-6 col-xl-4"
      >
        <HardpointCategory
          :category="category"
          :hardpoints="hardpointsForCategory(category)"
        />
      </div>
      <div
        v-for="category in ['RSIPropulsion', 'RSIThruster']"
        :key="category"
        class="col-12 col-lg-6 col-xl-4"
      >
        <HardpointCategory
          :category="category"
          :hardpoints="hardpointsForCategory(category)"
        />
      </div>
      <div
        v-for="category in ['RSIWeapon']"
        :key="category"
        class="col-12 col-lg-6 col-xl-4"
      >
        <HardpointCategory
          :category="category"
          :hardpoints="hardpointsForCategory(category)"
        />
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Btn from 'frontend/core/components/Btn'
import HardpointCategory from './Category'

@Component<Hardpoints>({
  components: {
    HardpointCategory,
    Btn,
  },
})
export default class Hardpoints extends Vue {
  @Prop({ required: true }) hardpoints!: Hardpoint[]

  @Prop({ default: null }) erkulUrl!: string

  hardpointsForCategory(category) {
    return this.hardpoints.filter(hardpoint => hardpoint.class === category)
  }
}
</script>

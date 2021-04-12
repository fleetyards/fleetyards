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
      <div class="col-12 col-md-6 col-lg-4">
        <HardpointGroup
          v-for="group in ['avionic', 'system']"
          :key="group"
          :group="group"
          :hardpoints="hardpointsForGroup(group)"
        />
      </div>
      <div class="col-12 col-md-6 col-lg-4">
        <HardpointGroup
          v-for="group in ['propulsion', 'thruster']"
          :key="group"
          :group="group"
          :hardpoints="hardpointsForGroup(group)"
        />
      </div>
      <div class="col-12 col-md-6 col-lg-4">
        <HardpointGroup
          v-for="group in ['weapon']"
          :key="group"
          :group="group"
          :hardpoints="hardpointsForGroup(group)"
        />
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Btn from 'frontend/core/components/Btn'
import HardpointGroup from './Group'

@Component<Hardpoints>({
  components: {
    HardpointGroup,
    Btn,
  },
})
export default class Hardpoints extends Vue {
  @Prop({ required: true }) hardpoints!: Hardpoint[]

  @Prop({ default: null }) erkulUrl!: string

  hardpointsForGroup(group) {
    return this.hardpoints.filter(hardpoint => hardpoint.group === group)
  }
}
</script>

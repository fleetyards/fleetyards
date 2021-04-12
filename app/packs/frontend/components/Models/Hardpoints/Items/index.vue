<template>
  <div class="hardpoint-item">
    <div class="hardpoint-item-quantity">
      {{ hardpoints.length }}
      <span class="text-muted">x</span>
    </div>
    <div class="hardpoint-item-slots">
      <HardpointItem
        v-for="(itemsByKey, key) in groupByCategory(hardpoints)"
        :key="`${key}`"
        :hardpoint="itemsByKey[0]"
      />
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import { groupBy } from 'frontend/lib/Helpers'
import HardpointItem from '../Item'

@Component<HardpointGroup>({
  components: {
    HardpointItem,
  },
})
export default class HardpointGroup extends Vue {
  @Prop({ required: true }) hardpoints: Hardpoint[]

  groupByCategory(hardpoints) {
    return groupBy(hardpoints, 'category')
  }
}
</script>

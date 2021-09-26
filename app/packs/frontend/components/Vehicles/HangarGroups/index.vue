<template>
  <div
    class="hangar-groups"
    :class="{
      'hangar-groups-large': size === 'large',
    }"
  >
    <div
      v-for="group in groups"
      :key="`hangar-group-${group.id}`"
      v-tooltip="group.name"
      class="hangar-group"
      :style="{
        'background-color': group.color,
      }"
    />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'

@Component<PanelGroups>({})
export default class PanelGroups extends Vue {
  @Prop({ required: true }) groups: HangarGroup[]

  @Prop({
    default: 'default',
    validator(value) {
      return ['default', 'large'].indexOf(value) !== -1
    },
  })
  size!: string
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>

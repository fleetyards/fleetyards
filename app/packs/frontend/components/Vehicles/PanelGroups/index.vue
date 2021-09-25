<template>
  <div class="panel-groups">
    <div
      v-for="(group, index) in groups"
      :key="index"
      v-tooltip="group.name"
      class="panel-group"
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
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>

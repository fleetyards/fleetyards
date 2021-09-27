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
      @click.exact="filter($event, group.slug)"
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

  filter(event, filter) {
    event.preventDefault()

    if (!filter) {
      return
    }

    const query = JSON.parse(JSON.stringify(this.$route.query.q || {}))

    if ((query.hangarGroupsIn || []).includes(filter)) {
      const index = query.hangarGroupsIn.findIndex(item => item === filter)
      if (index > -1) {
        query.hangarGroupsIn.splice(index, 1)
      }
    } else {
      if (!query.hangarGroupsIn) {
        query.hangarGroupsIn = []
      }
      query.hangarGroupsIn.push(filter)
    }

    this.$router.replace({
      name: this.$route.name,
      query: {
        q: query,
      },
    })
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>

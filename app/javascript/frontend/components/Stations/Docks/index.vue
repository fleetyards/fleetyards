<template>
  <div
    v-if="station.docks.length"
    class="row"
    :class="{
      'metrics-padding': padding,
    }"
  >
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ $t('labels.station.docks') }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
      <div class="row">
        <template v-if="hasGroup">
          <div
            v-for="(groupDocks, group) in docksByGroup"
            :key="`docks-${group}`"
            class="col-12"
          >
            <div class="metrics-group-label">
              <b>{{ group }}:</b>
            </div>
            <div class="row">
              <div
                v-for="(typedDocks, type) in docksByType(typedDocks)"
                :key="`docks-${group}-${type}`"
                class="col-12"
              >
                <div class="metrics-label">
                  <b>{{ type }}:</b>
                </div>
                <div class="row">
                  <div
                    v-for="(docks, size) in docksBySize(typedDocks)"
                    :key="`dock-${size}`"
                    class="col-6"
                  >
                    <DockItem :docks="docks" :size="size" />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </template>
        <div
          v-for="(groupDocks, group) in docksByType(station.docks)"
          v-else
          :key="`docks-${group}`"
          class="col-12"
        >
          <div class="metrics-label">
            <b>{{ group }}:</b>
          </div>
          <div class="row">
            <div
              v-for="(docks, size) in docksBySize(groupDocks)"
              :key="`dock-${size}`"
              class="col-6"
            >
              <DockItem :docks="docks" :size="size" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { groupBy, sortBy } from 'frontend/lib/Helpers'
import DockItem from './Item'

export default {
  components: {
    DockItem,
  },

  props: {
    station: {
      type: Object,
      required: true,
    },

    padding: {
      type: Boolean,
      default: false,
    },
  },

  computed: {
    hasGroup() {
      return this.station.docks.some(dock => !!dock.group)
    },

    docksByGroup() {
      return groupBy(sortBy(this.station.docks, 'name'), 'group')
    },
  },

  method: {
    docksBySize(docks) {
      return groupBy(docks, 'sizeLabel')
    },

    docksByType(docks) {
      return groupBy(docks, 'typeLabel')
    },
  },
}
</script>

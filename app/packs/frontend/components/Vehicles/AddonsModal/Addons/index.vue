<template>
  <div class="row">
    <div class="col-12">
      <div class="row">
        <template v-for="addon in addons">
          <div
            v-for="(addonId, index) in idsForAddon(addon.id)"
            :key="`${index}-${addonId}`"
            class="col-12 col-md-6 addon"
          >
            <Panel>
              <div
                v-tooltip="editable && selectTooltip(addon.id)"
                class="model-panel"
                :class="{
                  editable,
                }"
                @click.capture="changeAddon(addon.id)"
              >
                <div
                  :style="{
                    'background-image': `url(${addon.storeImage})`,
                  }"
                  class="model-panel-image"
                />
                <div class="model-panel-body">
                  <h3>{{ addon.name }}</h3>
                </div>
                <div
                  v-if="selectedAddon(addon.id)"
                  v-tooltip="editable && $t('labels.selected')"
                  class="model-panel-selected"
                >
                  <i class="fa fa-check" />
                </div>
              </div>
            </Panel>
          </div>
        </template>
      </div>
    </div>
    <div v-if="editable" class="col-12 col-md-6 add-addons">
      <FilterGroup
        v-model="addonToAdd"
        :label="label"
        :options="addons"
        name="addons"
        value-attr="id"
        :searchable="true"
        @input="addAddon"
      />
    </div>
  </div>
</template>

<script>
import Panel from 'frontend/core/components/Panel'
import FilterGroup from 'frontend/core/components/Form/FilterGroup'

export default {
  name: 'VehicleAddonsModal',

  components: {
    Panel,
    FilterGroup,
  },

  props: {
    addons: {
      type: Array,
      required: true,
    },

    label: {
      type: String,
      required: true,
    },

    value: {
      type: Array,
      required: true,
    },

    initialAddons: {
      type: Array,
      required: true,
    },

    editable: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      addonToAdd: null,
      internalAddons: [...this.value],
    }
  },

  watch: {
    value() {
      if (this.internalAddons !== this.value) {
        this.internalAddons = [...this.value]
      }
    },

    addons() {
      this.internalAddons = [...this.value]
    },

    internalAddons() {
      this.$emit('input', this.internalAddons)
    },
  },

  methods: {
    selectTooltip(addonId) {
      if (this.internalAddons.includes(addonId)) {
        return this.$t('labels.deselect')
      }
      return null
    },

    addAddon() {
      if (!this.addonToAdd) {
        return
      }
      this.internalAddons.push(this.addonToAdd)
      this.addonToAdd = null
    },

    idsForAddon(addonId) {
      const ids = this.internalAddons.filter((item) => item === addonId)
      if (ids.length) {
        return ids
      }
      return [addonId]
    },

    changeAddon(addonId) {
      if (!this.editable) {
        return
      }

      if (this.internalAddons.includes(addonId)) {
        const index = this.internalAddons.findIndex(
          (itemId) => itemId === addonId
        )
        if (index > -1) {
          this.internalAddons.splice(index, 1)
        }
      } else {
        this.internalAddons.push(addonId)
      }
    },

    selectedAddon(addonId) {
      return this.internalAddons.includes(addonId)
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>

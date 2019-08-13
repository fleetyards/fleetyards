<template>
  <div class="row">
    <div class="col-xs-12">
      <div class="flex-row">
        <template v-for="addon in addons">
          <div
            v-for="(addonId, index) in idsForAddon(addon.id)"
            :key="`${index}-${addonId}`"
            class="col-xs-12 col-sm-6 addon"
          >
            <Panel>
              <div
                v-tooltip="selectTooltip(addon.id)"
                class="model-panel"
                @click.capture="changeAddon(addon.id)"
              >
                <div
                  :style="{
                    'background-image': `url(${addon.storeImage})`
                  }"
                  class="model-panel-image"
                />
                <div class="model-panel-body">
                  <h3>{{ addon.name }}</h3>
                </div>
                <div
                  v-if="selectedAddon(addon.id)"
                  v-tooltip="$t('labels.selected')"
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
    <div class="col-xs-12 col-sm-6 add-addons">
      <FilterGroup
        v-model="addonToAdd"
        :label="label"
        :options="addons"
        name="addons"
        value-attr="id"
        searchable
        @input="addAddon"
      />
    </div>
  </div>
</template>

<script>
import Panel from 'frontend/components/Panel'
import FilterGroup from 'frontend/components/Form/FilterGroup'

export default {
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
  },

  data() {
    return {
      addonToAdd: null,
      availableAddons: [...this.value],
    }
  },

  watch: {
    addons() {
      this.availableAddons = [...this.value]
    },

    availableAddons() {
      this.$emit('input', this.availableAddons)
    },
  },

  methods: {
    selectTooltip(addonId) {
      if (this.availableAddons.includes(addonId)) {
        return this.$t('labels.deselect')
      }
      return null
    },

    addAddon() {
      if (!this.addonToAdd) {
        return
      }
      this.availableAddons.push(this.addonToAdd)
      this.addonToAdd = null
    },

    idsForAddon(addonId) {
      const ids = this.availableAddons.filter((item) => item === addonId)
      if (ids.length) {
        return ids
      }
      return [addonId]
    },

    changeAddon(addonId) {
      if (this.availableAddons.includes(addonId)) {
        const index = this.availableAddons.findIndex((itemId) => itemId === addonId)
        if (index > -1) {
          this.availableAddons.splice(index, 1)
        }
      } else {
        this.availableAddons.push(addonId)
      }
    },

    selectedAddon(addonId) {
      return this.value.includes(addonId)
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>

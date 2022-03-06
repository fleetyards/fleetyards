<template>
  <div class="row">
    <div v-for="item in packages" :key="item.id" class="col-12 col-md-6 addon">
      <Panel>
        <div
          v-tooltip="editable"
          class="model-panel"
          :class="{
            editable,
          }"
          @click="activatePackage(item)"
        >
          <div
            :style="{
              'background-image': `url(${item.storeImage})`,
            }"
            class="model-panel-image"
          />
          <div class="model-panel-body">
            <h3>{{ item.name }}</h3>
          </div>
          <div
            v-if="selectedPackage(item)"
            v-tooltip="editable && $t('labels.selected')"
            class="model-panel-selected"
          >
            <i class="fa fa-check" />
          </div>
        </div>
      </Panel>
    </div>
  </div>
</template>

<script>
import Panel from '@/frontend/core/components/Panel/index.vue'

export default {
  name: 'AddonsModal',

  components: {
    Panel,
  },

  props: {
    editable: {
      type: Boolean,
      default: false,
    },

    packages: {
      type: Array,
      required: true,
    },

    value: {
      type: Array,
      required: true,
    },
  },

  data() {
    return {
      internalValue: [],
    }
  },

  watch: {
    internalValue() {
      this.$emit('input', this.internalValue)
    },
  },

  mounted() {
    this.internalValue = [...this.value]
  },

  methods: {
    activatePackage(modulePackage) {
      if (!this.editable) {
        return
      }

      this.internalValue = [...this.value]

      modulePackage.modules.forEach((module) => {
        const additionalPackageModules = modulePackage.modules.filter(
          (item) => item.id === module.id
        )
        const foundModules = this.internalValue.filter((id) => id === module.id)

        if (
          !foundModules.length ||
          foundModules.length < additionalPackageModules.length
        ) {
          this.internalValue.push(module.id)
        }
      })
    },

    selectedPackage(modulePackage) {
      return (
        JSON.stringify([...this.value].sort()) ===
        JSON.stringify(modulePackage.modules.map((module) => module.id).sort())
      )
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>

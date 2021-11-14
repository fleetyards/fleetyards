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

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import Panel from 'frontend/core/components/Panel'

@Component<AddonsModal>({
  components: {
    Panel,
  },
})
export default class AddonsModal extends Vue {
  @Prop({ required: true }) value: string[]

  @Prop({ required: true }) packages: ModelModulePackage[]

  @Prop({ default: false }) editable: boolean

  internalValue: string[] = []

  mounted() {
    this.internalValue = [...this.value]
  }

  @Watch('internalValue')
  onInternalValueChange() {
    this.$emit('input', this.internalValue)
  }

  activatePackage(package) {
    if (!this.editable) {
      return
    }

    this.internalValue = [...this.value]

    package.modules.forEach(module => {
      const additionalPackageModules = package.modules.filter(
        packageModule => packageModule.id === module.id,
      )
      const foundModules = this.internalValue.filter(id => id === module.id)

      if (
        !foundModules.length ||
        foundModules.length < additionalPackageModules.length
      ) {
        this.internalValue.push(module.id)
      }
    })
  }

  selectedPackage(package) {
    return (
      JSON.stringify(this.value) ===
      JSON.stringify(package.modules.map(module => module.id))
    )
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>

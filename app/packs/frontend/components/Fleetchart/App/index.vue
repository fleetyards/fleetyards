<template>
  <div
    v-if="isShow"
    class="fleetchart-app fade"
    :class="{
      in: isOpen,
      show: isShow,
    }"
  >
    <BtnDropdown size="small" class="fleetchart-app-mode">
      <template #label>
        <template v-if="!mobile">
          {{ $t('labels.fleetchartApp.mode') }}:
        </template>
        {{ $t(`labels.fleetchartApp.modeOptions.${mode}`) }}
      </template>
      <Btn
        v-for="(option, index) in modeOptions"
        :key="`fleetchart-screen-height-drowndown-${index}-${option}`"
        size="small"
        variant="link"
        :active="mode === option"
        @click.native="setMode(option)"
      >
        {{ $t(`labels.fleetchartApp.modeOptions.${option}`) }}
      </Btn>
    </BtnDropdown>

    <Btn
      size="large"
      variant="link"
      class="fleetchart-app-close"
      @click.native="hide"
    >
      <i class="fal fa-times" />
    </Btn>

    <template v-if="innerItems.length">
      <FleetchartListPanzoom
        v-if="mode == 'panzoom'"
        :items="innerItems"
        :my-ship="myShip"
        :namespace="namespace"
        :download-name="downloadName"
      />
      <FleetchartList
        v-else
        :items="innerItems"
        :my-ship="myShip"
        :namespace="namespace"
        :download-name="downloadName"
      />
    </template>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import { Action, Getter } from 'vuex-class'
import FleetchartListPanzoom from 'frontend/components/Fleetchart/ListPanzoom'
import FleetchartList from 'frontend/components/Fleetchart/List'
import Btn from 'frontend/core/components/Btn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'

@Component({
  components: {
    FleetchartListPanzoom,
    FleetchartList,
    Btn,
    BtnDropdown,
  },
})
export default class FleetchartApp extends Vue {
  @Action('showOverlay', { namespace: 'app' }) showOverlay: any

  @Action('hideOverlay', { namespace: 'app' }) hideOverlay: any

  modeOptions: string[] = ['panzoom', 'classic']

  innerItems: Vehiclep[] | Model[] = []

  isOpen: boolean = false

  isShow: boolean = false

  @Prop({ required: true }) namespace!: string

  @Prop({
    default() {
      return []
    },
  })
  items!: Vehicle[] | Model[]

  @Prop({ default: false }) myShip!: boolean

  @Prop({ default: null }) downloadName!: string

  @Getter('mobile') mobile

  get visible() {
    return this.$store.getters[`${this.namespace}/fleetchartVisible`]
  }

  get mode() {
    return this.$store.getters[`${this.namespace}/fleetchartMode`]
  }

  @Watch('items')
  onItemsChange() {
    this.updateItems()
  }

  @Watch('visible')
  onVisibleChange() {
    if (this.visible) {
      this.open()
    } else {
      this.close()
    }
  }

  mounted() {
    this.updateItems()

    if (this.$route.query.fleetchart) {
      this.$store.commit(`${this.namespace}/setFleetchartVisible`, true)
    }

    if (this.visible) {
      this.open()
    }
  }

  updateItems() {
    this.innerItems = JSON.parse(JSON.stringify(this.items)).sort((a, b) => {
      if (a.model) {
        if (a.model.length < b.model.length) {
          return -1
        }

        if (a.model.length > b.model.length) {
          return 1
        }

        return 0
      }

      if (a.length < b.length) {
        return -1
      }

      if (a.length > b.length) {
        return 1
      }

      return 0
    })
  }

  open() {
    this.isShow = true
    this.showOverlay()

    this.$nextTick(() => {
      // make sure the component is present
      setTimeout(() => {
        // make sure initial animations have enough time
        this.isOpen = true

        this.$emit('fleetchart-opened')
      }, 100)
    })
  }

  hide() {
    this.$store.commit(`${this.namespace}/setFleetchartVisible`, false)
  }

  setMode(mode) {
    this.$store.commit(`${this.namespace}/setFleetchartMode`, mode)
  }

  close() {
    this.isOpen = false
    this.hideOverlay()

    this.$nextTick(function onClose() {
      setTimeout(() => {
        this.isShow = false

        this.$emit('fleetchart-closed')
      }, 300)
    })
  }
}
</script>

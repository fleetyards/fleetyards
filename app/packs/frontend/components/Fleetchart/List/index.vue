<template>
  <div class="row fleetchart-list">
    <div class="col-12 fleetchart-wrapper">
      <div class="fleetchart-controls">
        <Starship42Btn v-if="!mobile" size="small" :items="items" />

        <BtnDropdown size="small">
          <template #label>
            <template v-if="!mobile">
              {{ $t('labels.fleetchartApp.viewpoint') }}:
            </template>
            {{ $t(`labels.fleetchartApp.viewpointOptions.${viewpoint}`) }}
          </template>
          <Btn
            v-for="(option, index) in viewpointOptions"
            :key="`fleetchart-screen-height-drowndown-${index}-${option}`"
            size="small"
            variant="link"
            :active="viewpoint === option"
            @click.native="setViewpoint(option)"
          >
            {{ $t(`labels.fleetchartApp.viewpointOptions.${option}`) }}
          </Btn>
        </BtnDropdown>

        <Btn size="small" :active="gridEnabled" @click.native="toggleGrid">
          <i class="fad fa-th" />
        </Btn>

        <BtnDropdown size="small">
          <template v-if="downloadName">
            <DownloadScreenshotBtn
              element="#fleetchart"
              :filename="downloadName"
              size="small"
              variant="dropdown"
            />

            <hr />
          </template>

          <Starship42Btn
            v-if="mobile"
            :items="items"
            size="small"
            variant="dropdown"
            :with-icon="true"
          />

          <Btn size="small" variant="dropdown" @click.native="toggleLabels">
            <i class="fad fa-tags" />
            <span v-if="showLabels">
              {{ $t('actions.hideLabels') }}
            </span>
            <span v-else>
              {{ $t('actions.showLabels') }}
            </span>
          </Btn>

          <FleetChartStatusBtn variant="dropdown" size="small" />
        </BtnDropdown>
      </div>

      <div
        class="fleetchart-grid-label"
        :class="{
          'fleetchart-grid-enabled': gridEnabled,
        }"
      >
        {{ $t('labels.fleetchartApp.gridSize', { size: gridSizeLabel }) }}
      </div>

      <div class="fleetchart-scroll-wrapper">
        <transition-group
          id="fleetchart"
          name="fade-list"
          :appear="true"
          tag="div"
          class="fleetchart"
        >
          <FleetchartItem
            v-for="item in items"
            :key="item.id"
            :item="item"
            :viewpoint="viewpoint"
            :show-label="showLabels"
            :show-status="showStatus"
            :size-multiplicator="sizeMultiplicator"
            :scale="scale"
          />
          <div
            key="made-by-the-community"
            class="fleetchart-item fade-list-item fleetchart-download-image"
          >
            <img
              :src="require('images/community-logo.png')"
              alt="made-by-the-community"
            />
          </div>
        </transition-group>
        <canvas
          ref="fleetchartGrid"
          class="fleetchart-grid"
          :class="{
            'fleetchart-grid-enabled': gridEnabled,
          }"
          :width="screenWidth"
          :height="screenHeight"
        />
      </div>

      <FleetchartSlider
        v-model="internalScale"
        :min-scale="minScale"
        :max-scale="maxScale"
      />
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import FleetchartSlider from 'frontend/components/Fleetchart/Slider/index.vue'
import Btn from 'frontend/core/components/Btn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import FleetChartStatusBtn from 'frontend/components/FleetChartStatusBtn'
import { Getter } from 'vuex-class'
import Starship42Btn from 'frontend/components/Starship42Btn'
import FleetchartItem from './Item/index.vue'

@Component({
  components: {
    Btn,
    BtnDropdown,
    DownloadScreenshotBtn,
    FleetChartStatusBtn,
    FleetchartItem,
    FleetchartSlider,
    Starship42Btn,
  },
})
export default class FleetchartList extends Vue {
  viewpointOptions: string[] = ['side', 'top', 'angled']

  showStatus: boolean = false

  gridEnabled: boolean = false

  screenWidth: number | null = null

  screenHeight: number | null = null

  gridSize: number = 80.0

  sizeMultiplicator: number = 4

  internalScale: number = 1

  maxScale: number = 20

  minScale: number = 0.5

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

  get gridSizeLabel() {
    return (this.gridSize / this.scale / this.sizeMultiplicator)
      .toFixed(2)
      .replace('.00', '')
  }

  get scale() {
    return this.$store.getters[`${this.namespace}/fleetchartScale`]
  }

  get viewpoint() {
    return this.$store.getters[`${this.namespace}/fleetchartViewpoint`]
  }

  get showLabels() {
    return this.$store.getters[`${this.namespace}/fleetchartLabels`]
  }

  @Watch('internalScale')
  onScaleChange() {
    this.$store.commit(
      `${this.namespace}/setFleetchartScale`,
      this.internalScale
    )
  }

  mounted() {
    this.internalScale = this.scale

    this.showStatus = !!this.$route.query?.showStatus

    this.$comlink.$on('fleetchart-toggle-status', this.toggleStatus)

    this.updateScreenSize()

    window.addEventListener('resize', this.updateScreenSize)
    window.addEventListener('deviceorientation', this.updateScreenSize)
  }

  beforeDestroy() {
    this.$comlink.$off('fleetchart-toggle-status')

    window.removeEventListener('resize', this.updateScreenSize)
    window.removeEventListener('deviceorientation', this.updateScreenSize)
  }

  modelName(item) {
    const model = item.model || item

    return model.name
  }

  productionStatus(item) {
    const model = item.model || item

    return this.$t(`labels.model.productionStatus.${model.productionStatus}`)
  }

  updateScreenSize() {
    this.screenWidth = window.innerWidth
    this.screenHeight = window.innerHeight

    this.drawGridLines()
  }

  toggleGrid() {
    this.gridEnabled = !this.gridEnabled

    this.drawGridLines()
  }

  setViewpoint(viewpoint) {
    this.$store.commit(`${this.namespace}/setFleetchartViewpoint`, viewpoint)
  }

  toggleStatus() {
    this.showStatus = !this.showStatus
  }

  toggleLabels() {
    this.$store.commit(
      `${this.namespace}/setFleetchartLabels`,
      !this.showLabels
    )
  }

  async drawGridLines() {
    if (!this.gridEnabled) {
      return
    }

    await this.$nextTick()

    const canvas = this.$refs.fleetchartGrid

    if (canvas.getContext) {
      const ctx = canvas.getContext('2d')

      ctx.clearRect(0, 0, canvas.width, canvas.height)

      ctx.drawVerticalLine = (left, top, height, color) => {
        ctx.fillStyle = color
        ctx.fillRect(left, top, 1, height)
      }

      ctx.drawHorizontalLine = (left, top, width, color) => {
        ctx.fillStyle = color
        ctx.fillRect(left, top, width, 1)
      }

      const lineColor = 'rgba(255, 255, 255, 0.5)'

      for (let i = 0; i < canvas.width; i += this.gridSize) {
        ctx.drawVerticalLine(i, 0, canvas.height, lineColor)
      }

      for (let i = 0; i < canvas.height; i += this.gridSize) {
        ctx.drawHorizontalLine(0, i, canvas.width, lineColor)
      }
    }
  }
}
</script>

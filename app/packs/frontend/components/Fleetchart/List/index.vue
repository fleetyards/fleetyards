<template>
  <div class="row">
    <div class="col-12 fleetchart-wrapper">
      <div class="fleetchart-controls">
        <BtnDropdown size="small">
          <template #label>
            <template v-if="!mobile">
              {{ $t('labels.fleetchartApp.screenHeight') }}:
            </template>
            {{ $t(`labels.fleetchartApp.screenHeightOptions.${screenHeight}`) }}
          </template>
          <Btn
            v-for="(option, index) in screenHeightOptions"
            :key="`fleetchart-screen-height-drowndown-${index}-${option}`"
            size="small"
            variant="link"
            :active="screenHeight === option"
            @click.native="setScreenHeight(option)"
          >
            {{ $t(`labels.fleetchartApp.screenHeightOptions.${option}`) }}
          </Btn>
        </BtnDropdown>
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

          <Btn
            size="small"
            variant="dropdown"
            :active="showLabels"
            @click.native="toggleLabels"
          >
            <i class="fad fa-tags" />
            <span v-if="showLabels">
              {{ $t('actions.hideLabels') }}
            </span>
            <span v-else>
              {{ $t('actions.showLabels') }}
            </span>
          </Btn>

          <FleetChartStatusBtn variant="dropdown" size="small" />

          <Btn size="small" variant="dropdown" @click.native="resetZoom">
            <i class="fad fa-undo" />
            <span>{{ $t('actions.resetZoom') }}</span>
          </Btn>
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
      <div ref="fleetchartWrapper" class="fleetchart-scroll-wrapper">
        <transition-group
          id="fleetchart"
          name="fade-list"
          class="fleetchart"
          tag="div"
          :appear="true"
          :class="{
            'fleetchart-1_5x': screenHeight === '1_5x',
            'fleetchart-2x': screenHeight === '2x',
            'fleetchart-3x': screenHeight === '3x',
            'fleetchart-4x': screenHeight === '4x',
          }"
        >
          <div key="made-by-the-community" class="fleetchart-download-image">
            <img
              :src="require('images/community-logo.png')"
              alt="made-by-the-community"
            />
          </div>

          <FleetchartItem
            v-for="item in items"
            :key="item.id"
            :item="item"
            :viewpoint="viewpoint"
            :show-label="showLabels"
            :show-status="showStatus"
            :size-multiplicator="sizeMultiplicator"
          />
        </transition-group>
        <canvas
          ref="fleetchartGrid"
          class="fleetchart-grid"
          :class="{
            'fleetchart-grid-enabled': gridEnabled,
          }"
          :width="canvasWidth"
          :height="canvasHeight"
        />
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import FleetchartItem from 'frontend/components/Fleetchart/List/Item/index.vue'
import panzoom from 'panzoom'
import Btn from 'frontend/core/components/Btn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import FleetChartStatusBtn from 'frontend/components/FleetChartStatusBtn'
import { Getter } from 'vuex-class'
import debounce from 'lodash.debounce'

@Component({
  components: {
    Btn,
    BtnDropdown,
    DownloadScreenshotBtn,
    FleetChartStatusBtn,
    FleetchartItem,
  },
})
export default class FleetchartList extends Vue {
  updateZoomData: Function = debounce(this.debouncedUpdateZoomData, 300)

  screenHeightOptions: string[] = ['1x', '1_5x', '2x', '3x', '4x']

  viewpointOptions: string[] = ['side', 'top', 'angled']

  showStatus: boolean = false

  selectedModel: Model | null = null

  selectedVehicle: Vehicle | null = null

  zoomSpeed: number = 0.05

  maxZoom: number = 10

  minZoom: number = 0.5

  pinchSpeed: number = 2

  panzoomInstance = null

  gridEnabled: boolean = false

  canvasWidth: number = 300

  canvasHeight: number = 300

  gridSize: number = 80.0

  @Getter('mobile') mobile

  @Prop({ required: true }) namespace!: string

  @Prop({
    default() {
      return []
    },
  })
  items!: Vehicle[] | Model[]

  @Prop({ default: false }) myShip!: boolean

  @Prop({ default: null }) downloadName!: string

  get fleetchartElement() {
    return this.$refs.fleetchartWrapper?.children.item(0)
  }

  get sizeMultiplicator() {
    if (this.viewpoint === 'angled') {
      return 3
    }

    return 4
  }

  get gridSizeLabel() {
    return (
      this.gridSize /
      (this.initialZoomData?.scale || 1) /
      this.sizeMultiplicator
    )
      .toFixed(2)
      .replace('.00', '')
  }

  get initialZoomData() {
    return this.$store.getters[`${this.namespace}/fleetchartZoomData`]
  }

  get viewpoint() {
    return this.$store.getters[`${this.namespace}/fleetchartViewpoint`]
  }

  get showLabels() {
    return this.$store.getters[`${this.namespace}/fleetchartLabels`]
  }

  get screenHeight() {
    return this.$store.getters[`${this.namespace}/fleetchartScreenHeight`]
  }

  mounted() {
    this.showStatus = !!this.$route.query?.showStatus

    this.$comlink.$on('fleetchart-toggle-status', this.toggleStatus)

    this.setupZoom()

    this.drawGridLines()

    window.addEventListener('resize', this.updateCanvasSize)
    window.addEventListener('deviceorientation', this.updateCanvasSize)
  }

  beforeDestroy() {
    this.$comlink.$off('fleetchart-toggle-status')

    this.panzoomInstance.dispose()

    this.panzoomInstance = null

    window.removeEventListener('resize', this.updateCanvasSize)
    window.removeEventListener('deviceorientation', this.updateCanvasSize)
  }

  updateCanvasSize() {
    this.canvasWidth = this.$refs.fleetchartWrapper.clientWidth
    this.canvasHeight = this.$refs.fleetchartWrapper.clientHeight
  }

  async setupZoom() {
    this.panzoomInstance = panzoom(this.fleetchartElement, {
      maxZoom: this.maxZoom,
      minZoom: this.minZoom,
      zoomSpeed: this.zoomSpeed,
      pinchSpeed: this.pinchSpeed,
    })

    if (this.initialZoomData?.scale) {
      this.panzoomInstance.zoomAbs(0, 0, this.initialZoomData.scale)

      // hack to apply latest location after zooming.
      setTimeout(() => {
        this.panzoomInstance.moveTo(
          this.initialZoomData.x,
          this.initialZoomData.y,
        )
      }, 300)
    }

    this.panzoomInstance.on('zoom', _event => {
      this.updateZoomData()
    })

    this.panzoomInstance.on('pan', _event => {
      this.updateZoomData()
    })
  }

  resetZoom() {
    this.panzoomInstance.moveTo(0, 0)
    this.panzoomInstance.zoomAbs(0, 0, 1)
  }

  toggleGrid() {
    this.gridEnabled = !this.gridEnabled

    this.drawGridLines()
  }

  setViewpoint(viewpoint) {
    this.$store.commit(`${this.namespace}/setFleetchartViewpoint`, viewpoint)
  }

  setScreenHeight(screenHeight) {
    this.$store.commit(
      `${this.namespace}/setFleetchartScreenHeight`,
      screenHeight,
    )
  }

  toggleStatus() {
    this.showStatus = !this.showStatus
  }

  toggleLabels() {
    this.$store.commit(
      `${this.namespace}/setFleetchartLabels`,
      !this.showLabels,
    )
  }

  debouncedUpdateZoomData() {
    const transform = this.panzoomInstance.getTransform()

    this.$store.commit(`${this.namespace}/setFleetchartZoomData`, transform)
  }

  async drawGridLines() {
    if (!this.gridEnabled) {
      return
    }

    this.canvasWidth = this.$refs.fleetchartWrapper.clientWidth
    this.canvasHeight = this.$refs.fleetchartWrapper.clientHeight

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

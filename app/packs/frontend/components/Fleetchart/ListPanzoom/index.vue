<template>
  <div class="row fleetchart-list-panzoom">
    <div class="col-12 fleetchart-wrapper">
      <div class="fleetchart-controls">
        <Starship42Btn v-if="!mobile" size="small" :items="items" />

        <BtnDropdown size="small">
          <template #label>
            <template v-if="!mobile">
              {{ $t('labels.fleetchartApp.screenHeight') }}:
            </template>
            {{
              $t(
                `labels.fleetchartApp.screenHeightOptions.${selectedScreenHeight}`
              )
            }}
          </template>
          <Btn
            v-for="(option, index) in screenHeightOptions"
            :key="`fleetchart-screen-height-drowndown-${index}-${option}`"
            size="small"
            variant="link"
            :active="selectedScreenHeight === option"
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

          <Btn size="small" variant="dropdown" @click.native="markForReset">
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
      <div class="fleetchart-scroll-wrapper">
        <div id="fleetchart" ref="fleetchart" class="fleetchart">
          <transition-group
            v-for="(items, index) in fleetchartColumns"
            :key="`fleetchart-col-${index}`"
            name="fade-list"
            :appear="true"
            class="fleetchart-column"
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
          </transition-group>

          <transition-group
            name="fade-list"
            tag="div"
            :appear="true"
            class="fleetchart-download-image"
          >
            <div
              key="made-by-the-community"
              class="fleetchart-item fade-list-item"
            >
              <img
                :src="require('images/community-logo.png')"
                alt="made-by-the-community"
              />
            </div>
          </transition-group>
        </div>
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
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import panzoom from 'panzoom'
import Btn from 'frontend/core/components/Btn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import FleetChartStatusBtn from 'frontend/components/FleetChartStatusBtn'
import { Getter } from 'vuex-class'
import debounce from 'lodash.debounce'
import Starship42Btn from 'frontend/components/Starship42Btn'
import FleetchartItem from './Item/index.vue'

@Component({
  components: {
    Btn,
    BtnDropdown,
    DownloadScreenshotBtn,
    FleetChartStatusBtn,
    FleetchartItem,
    Starship42Btn,
  },
})
export default class FleetchartListPanzoom extends Vue {
  updateZoomData: Function = debounce(this.debouncedUpdateZoomData, 300)

  checkReset: Function = debounce(this.debouncedCheckReset, 300)

  screenHeightOptions: string[] = ['1x', '1_5x', '2x', '3x', '4x']

  viewpointOptions: string[] = ['side', 'top', 'angled']

  showStatus: boolean = false

  zoomSpeed: number = 0.5

  maxZoom: number = 20

  minZoom: number = 0.2

  pinchSpeed: number = 3

  margin: number = 80

  innerMargin: number = 20

  marginBottom: number = 40

  gridEnabled: boolean = false

  screenWidth: number | null = null

  screenHeight: number | null = null

  gridSize: number = 80.0

  panzoomInstance = null

  fleetchartColumns = {}

  markedForReset: boolean = false

  sizeMultiplicator: number = 4

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

  get gridSizeLabel() {
    return (
      this.gridSize /
      (this.initialZoomData?.scale || 1) /
      this.sizeMultiplicator
    )
      .toFixed(2)
      .replace('.00', '')
  }

  get viewpoint() {
    return this.$store.getters[`${this.namespace}/fleetchartViewpoint`]
  }

  get showLabels() {
    return this.$store.getters[`${this.namespace}/fleetchartLabels`]
  }

  get selectedScreenHeight() {
    return this.$store.getters[`${this.namespace}/fleetchartScreenHeight`]
  }

  get viewpointTop() {
    return this.viewpoint === 'top'
  }

  get viewpointSide() {
    return this.viewpoint === 'side'
  }

  get viewpointAngled() {
    return this.viewpoint === 'angled'
  }

  get screenHeightFactor() {
    return {
      '1x': 1,
      '1_5x': 1.5,
      '2x': 2,
      '3x': 3,
      '4x': 4,
    }[this.selectedScreenHeight]
  }

  get maxColHeight() {
    return (
      this.screenHeight * this.screenHeightFactor -
      this.margin -
      this.marginBottom
    )
  }

  get initialZoomData() {
    return this.$store.getters[`${this.namespace}/fleetchartZoomData`]
  }

  get scale() {
    return this.initialZoomData?.scale || 1
  }

  mounted() {
    this.showStatus = !!this.$route.query?.showStatus

    this.$comlink.$on('fleetchart-toggle-status', this.toggleStatus)

    this.updateScreenSize()

    this.setupColumns()

    this.setupZoom()

    window.addEventListener('resize', this.updateScreenSize)
    window.addEventListener('deviceorientation', this.updateScreenSize)
  }

  beforeDestroy() {
    this.$comlink.$off('fleetchart-toggle-status')

    this.panzoomInstance.dispose()

    this.panzoomInstance = null

    window.removeEventListener('resize', this.updateScreenSize)
    window.removeEventListener('deviceorientation', this.updateScreenSize)
  }

  debouncedUpdateZoomData() {
    const transform = this.panzoomInstance.getTransform()

    this.$store.commit(`${this.namespace}/setFleetchartZoomData`, transform)
  }

  async setupZoom() {
    this.panzoomInstance = panzoom(this.$refs.fleetchart, {
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
          this.initialZoomData.y
        )
      }, 300)
    }

    this.panzoomInstance.on('zoom', (_event) => {
      this.updateZoomData()
    })

    this.panzoomInstance.on('pan', (_event) => {
      this.updateZoomData()
    })

    this.panzoomInstance.on('transform', (_event) => {
      this.checkReset()
    })
  }

  modelName(item) {
    const model = item.model || item

    return model.name
  }

  productionStatus(item) {
    const model = item.model || item

    return this.$t(`labels.model.productionStatus.${model.productionStatus}`)
  }

  debouncedCheckReset() {
    if (this.markedForReset) {
      this.markedForReset = false

      this.resetZoom()
    }
  }

  updateScreenSize() {
    this.screenWidth = window.innerWidth
    this.screenHeight = window.innerHeight

    this.drawGridLines()
  }

  setupColumns() {
    this.fleetchartColumns = {}
    let index = 0
    let colHeight = 0

    this.items.forEach((item) => {
      const model = item.model || item
      const length = model.fleetchartLength * this.sizeMultiplicator

      const height =
        (length * this.imageMaxHeight(item)) / this.imageMaxWidth(item)

      if (Number.isNaN(height)) {
        return
      }

      colHeight += height

      if (colHeight > this.maxColHeight) {
        colHeight = height
        index += 1
      }

      colHeight += this.innerMargin

      this.fleetchartColumns[index] = [
        ...(this.fleetchartColumns[index] || []),
        item,
      ]
    })
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
      screenHeight
    )

    this.setupColumns()
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

  image(item) {
    const model = item.model || item

    if (
      item.modulePackage &&
      (item.modulePackage.topView ||
        item.modulePackage.sideView ||
        item.modulePackage.angledView)
    ) {
      const url = this.extractUrlFromModel(item.modulePackage)
      if (url) {
        return url
      }
    }

    if (
      item.paint &&
      (item.paint.topView || item.paint.sideView || item.paint.angledView)
    ) {
      const url = this.extractUrlFromModel(item.paint)
      if (url) {
        return url
      }
    }

    return this.extractUrlFromModel(model)
  }

  extractUrlFromModel(model) {
    if (this.viewpointTop && model.topView) {
      return this.topView(model)
    }

    if (this.viewpointSide && model.sideView) {
      return this.sideView(model)
    }

    if (this.viewpointAngled && model.angledView) {
      return this.angledView(model)
    }

    return null
  }

  resetZoom() {
    this.panzoomInstance.zoomAbs(0, 0, 1)
    this.panzoomInstance.moveTo(0, 0)
  }

  markForReset() {
    this.markedForReset = true

    setTimeout(() => {
      this.checkReset()
    }, 300)
  }

  topView(model) {
    return model.topViewResized
  }

  sideView(model) {
    return model.sideViewResized
  }

  angledView(model) {
    return model.angledViewResized
  }

  extractMaxWidthFromModel(model) {
    return Math.max(
      model.topViewWidth,
      model.sideViewWidth,
      model.angledViewWidth
    )
  }

  extractMaxHeightFromModel(model) {
    return Math.max(
      model.topViewHeight,
      model.sideViewHeight,
      model.angledViewHeight
    )
  }

  imageMaxHeight(item) {
    const model = item.model || item

    if (
      item.modulePackage &&
      (item.modulePackage.topView ||
        item.modulePackage.sideView ||
        item.modulePackage.angledView)
    ) {
      const height = this.extractMaxHeightFromModel(item.modulePackage)
      if (height) {
        return height
      }
    }

    if (
      item.paint &&
      (item.paint.topView || item.paint.sideView || item.paint.angledView)
    ) {
      const height = this.extractMaxHeightFromModel(item.paint)
      if (height) {
        return height
      }
    }

    return this.extractMaxHeightFromModel(model)
  }

  imageMaxWidth(item) {
    const model = item.model || item

    if (
      item.modulePackage &&
      (item.modulePackage.topView ||
        item.modulePackage.sideView ||
        item.modulePackage.angledView)
    ) {
      const width = this.extractMaxWidthFromModel(item.modulePackage)
      if (width) {
        return width
      }
    }

    if (
      item.paint &&
      (item.paint.topView || item.paint.sideView || item.paint.angledView)
    ) {
      const width = this.extractMaxWidthFromModel(item.paint)
      if (width) {
        return width
      }
    }

    return this.extractMaxWidthFromModel(model)
  }
}
</script>

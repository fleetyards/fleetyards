<template>
  <div v-show="loaded" class="row">
    <div class="col-12 fleetchart-wrapper">
      <div class="fleetchart-controls">
        <!-- <BtnDropdown size="small">
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
        </BtnDropdown> -->
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
            <Btn size="small" variant="dropdown" @click.native="download">
              <i class="fad fa-image" />
              <span>
                {{ $t('actions.saveScreenshot') }}
              </span>
            </Btn>

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
        <input v-model="scale" step="0.01" type="number" />
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
        <canvas
          ref="fleetchartGrid"
          class="fleetchart-grid"
          :class="{
            'fleetchart-grid-enabled': gridEnabled,
          }"
          :width="screenWidth"
          :height="screenHeight"
        />
        <canvas
          id="fleetchart"
          class="fleetchart-canvas"
          :width="screenWidth"
          :height="screenHeight"
        />
        <transition-group
          id="fleetchart"
          ref="fleetchart"
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
      </div>
    </div>
    <Loader v-if="!loaded" :loading="!loaded" :fixed="true" />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import FleetchartItem from 'frontend/components/Fleetchart/ListPanzoom/Item/index.vue'
import Btn from 'frontend/core/components/Btn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import FleetChartStatusBtn from 'frontend/components/FleetChartStatusBtn'
import { Getter } from 'vuex-class'
// import { fabric } from 'fabric'
import Loader from 'frontend/core/components/Loader'
import download from 'downloadjs'

@Component({
  components: {
    Btn,
    BtnDropdown,
    DownloadScreenshotBtn,
    FleetChartStatusBtn,
    FleetchartItem,
    Loader,
  },
})
export default class FleetchartListFabric extends Vue {
  viewpointOptions: string[] = ['side', 'top', 'angled']

  showStatus: boolean = false

  selectedModel: Model | null = null

  selectedVehicle: Vehicle | null = null

  canvas = null

  scale: number = 0.5

  margin: number = 80

  loaded: boolean = true

  gridEnabled: boolean = false

  screenWidth: number = 1920

  screenHeight: number = 1080

  gridSize: number = 80.0

  zoomLevel: string = 'large'

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

  get viewpoint() {
    return this.$store.getters[`${this.namespace}/fleetchartViewpoint`]
  }

  get showLabels() {
    return this.$store.getters[`${this.namespace}/fleetchartLabels`]
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

  get innerMargin() {
    return this.margin / 2
  }

  get maxColHeight() {
    return this.screenHeight - this.margin * 2
  }

  get testModel() {
    return this.items
      .map((item) => (item.model ? item.model : item))
      .find((item) => item.slug === 'apollo-medivac')
  }

  // @Watch('zoomLevel')
  // onZoomLevelChange() {
  //   this.renderShips()
  // }

  mounted() {
    this.showStatus = !!this.$route.query?.showStatus

    this.$comlink.$on('fleetchart-toggle-status', this.toggleStatus)

    this.setupFabricCanvas()
    // this.setupCanvas()

    this.updateCanvasSize()

    this.drawGridLines()

    this.renderShips()

    window.addEventListener('resize', this.updateCanvasSize)
    window.addEventListener('deviceorientation', this.updateCanvasSize)
  }

  beforeDestroy() {
    this.$comlink.$off('fleetchart-toggle-status')

    this.canvas = null

    window.removeEventListener('resize', this.updateCanvasSize)
    window.removeEventListener('deviceorientation', this.updateCanvasSize)
  }

  download() {
    download(this.canvas.toDataURL(), `fleetyards-${this.downloadName}.png`)
  }

  updateCanvasSize() {
    this.screenWidth = window.innerWidth
    this.screenHeight = window.innerHeight

    this.canvas.setWidth(this.screenWidth)
    this.canvas.setHeight(this.screenHeight)

    this.canvas.renderAll()
  }

  // setupCanvas() {
  //   const can = document.getElementById('fleetchart')
  //   const ctx = can.getContext('2d')

  //   ctx.clearRect(0, 0, can.width, can.height)

  //   const img = new Image()
  //   const w = 2200
  //   const h = 433
  //   img.onload = () => {
  //     // step it down only once to 1/6 size:
  //     ctx.drawImage(img, 0, 0, w / 6, h / 6)

  //     // Step it down several times
  //     const can2 = document.createElement('canvas')
  //     can2.width = w / 2
  //     can2.height = w
  //     const ctx2 = can2.getContext('2d')

  //     // Draw it at 1/2 size 3 times (step down three times)

  //     ctx2.drawImage(img, 0, 600, w / 2, h / 2)
  //     ctx2.drawImage(can2, 0, 600, w / 2, h / 2, 0, 400, w / 4, h / 4)
  //     ctx2.drawImage(can2, 0, 400, w / 4, h / 4, 0, 0, w / 6, h / 6)
  //     ctx.drawImage(can2, 0, 0, w / 6, h / 6, 0, 200, w / 6, h / 6)
  //   }

  //   const model = this.items
  //     .map((item) => (item.model ? item.model : item))
  //     .find((item) => item.slug === 'apollo-medivac')

  //   img.src = this.image(model)
  // }

  setupFabricCanvas() {
    this.screenWidth = window.innerWidth
    this.screenHeight = window.innerHeight

    this.canvas = new fabric.Canvas('fleetchart', {
      selection: false,
      hasControls: false,
    })

    fabric.Group.prototype.hasControls = false
    fabric.Object.prototype.objectCaching = false

    this.canvas.setWidth(this.screenWidth)
    this.canvas.setHeight(this.screenHeight)

    this.setupCanvas(document.getElementById('fleetchart'))

    this.canvas.requestRenderAll()

    this.setupDragging()
    this.setupZoom()
  }

  setupCanvas(canvas) {
    // Get the device pixel ratio, falling back to 1.
    const dpr = window.devicePixelRatio || 1
    // Get the size of the canvas in CSS pixels.
    const rect = canvas.getBoundingClientRect()
    // Give the canvas pixel dimensions of their CSS
    // size * the device pixel ratio.
    canvas.width = rect.width * dpr
    canvas.height = rect.height * dpr
    const ctx = canvas.getContext('2d')
    // Scale all drawing operations by the dpr, so you
    // don't have to worry about the difference.
    ctx.scale(dpr, dpr)

    return ctx
  }

  setupDragging() {
    this.canvas.on('mouse:down', function mouseDown(opt) {
      const evt = opt.e
      // if (evt.altKey === true) {
      this.isDragging = true
      this.selection = false
      this.lastPosX = evt.clientX
      this.lastPosY = evt.clientY
      // }
    })

    this.canvas.on('mouse:move', function mouseMove(opt) {
      if (this.isDragging) {
        const { e } = opt
        const vpt = this.viewportTransform
        vpt[4] += e.clientX - this.lastPosX
        vpt[5] += e.clientY - this.lastPosY
        this.requestRenderAll()
        this.lastPosX = e.clientX
        this.lastPosY = e.clientY
      }
    })

    this.canvas.on('mouse:up', function mouseUp(_opt) {
      this.setViewportTransform(this.viewportTransform)
      this.isDragging = false
      this.selection = true
    })
  }

  setupZoom() {
    this.canvas.on('mouse:wheel', (opt) => {
      const delta = opt.e.deltaY
      let zoom = this.canvas.getZoom()
      zoom *= 0.999 ** delta

      if (zoom > 30) zoom = 30

      if (zoom < 0.2) zoom = 0.2

      this.canvas.zoomToPoint({ x: opt.e.offsetX, y: opt.e.offsetY }, zoom)

      this.updateZoomLevel(zoom)

      opt.e.preventDefault()
      opt.e.stopPropagation()
    })
  }

  setupColumns() {
    let index = 0
    let height = 0
    const cols = {}

    this.items.forEach((item) => {
      const model = item.model || item
      const length = model.fleetchartLength * this.sizeMultiplicator

      if (!this.imageHeight(model)) {
        return
      }

      height += (length * this.imageHeight(model)) / this.imageWidth(model)
      height += this.innerMargin

      if (height > this.maxColHeight) {
        height = 0
        index += 1
      }

      cols[index] = [...(cols[index] || []), item]
    })

    return cols
  }

  async renderShips() {
    this.canvas.clear()

    const cols = this.setupColumns()

    let colOffset = this.margin

    const promisses = []

    Object.keys(cols).forEach((columnIndex) => {
      const lastItem = cols[columnIndex][cols[columnIndex].length - 1]
      const lastItemModel = lastItem.model || lastItem
      const maxColLength = lastItemModel.length * this.sizeMultiplicator

      let positionTop = this.margin

      cols[columnIndex].forEach((item, index) => {
        if (index > 1) {
          return
        }

        const model = item.model || item
        const src = this.image(model, this.canvas.getZoom())

        const length = model.fleetchartLength * this.sizeMultiplicator

        if (!this.imageHeight(model)) {
          return
        }

        const height =
          (length * this.imageHeight(model)) / this.imageWidth(model)

        const top = positionTop
        const left = colOffset + (maxColLength - length)

        promisses.push(
          new Promise((resolve) => {
            this.loadImage(src, top, left, length, (image) => {
              cols[columnIndex].canvasImage = image
              resolve()
            })
          })
        )

        positionTop += height
        positionTop += this.innerMargin
      })

      colOffset += maxColLength
      colOffset += this.margin
    })

    await Promise.all(promisses)

    this.canvas.renderAll()

    this.loaded = true
  }

  loadImage(src, top, left, length, callback = null) {
    fabric.Image.fromURL(src, (image) => {
      image.objectCaching = false

      image.set({
        left,
        top,
        controls: false,
        selectable: false,
        lockRotation: true,
        lockScalingFlip: true,
        lockScalingX: true,
        lockScalingY: true,
        lockSkewingX: true,
        lockSkewingY: true,
      })

      // image.scaleToWidth(length)

      image.resizeFilter = new fabric.Image.filters.Resize({
        resizeType: 'lanczos',
      })
      image.applyResizeFilters()

      this.canvas.add(image)

      this.canvas.renderAll()

      if (callback) {
        callback(image)
      }
    })
  }

  toggleGrid() {
    this.gridEnabled = !this.gridEnabled

    this.drawGridLines()
  }

  setViewpoint(viewpoint) {
    this.$store.commit(`${this.namespace}/setFleetchartViewpoint`, viewpoint)

    this.renderShips()
  }

  updateZoomLevel(zoom) {
    if (zoom > 10) {
      this.zoomLevel = ''
      return
    }

    if (zoom > 7.9) {
      this.zoomLevel = 'xlarge'
      return
    }

    if (zoom > 3.9) {
      this.zoomLevel = 'large'
      return
    }

    if (zoom > 1.9) {
      this.zoomLevel = 'medium'
      return
    }

    this.zoomLevel = 'small'
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

  image(model, zoom = 1) {
    if (model.paint && (model.paint.topView || model.paint.sideView)) {
      const url = this.extractUrlFromModel(model.paint, zoom)
      if (url) {
        return url
      }
    }

    return this.extractUrlFromModel(model, zoom)
  }

  extractUrlFromModel(model, zoom) {
    if (this.viewpointTop && model.topView) {
      return this.topView(model, zoom)
    }

    if (this.viewpointSide && model.sideView) {
      return this.sideView(model, zoom)
    }

    if (this.viewpointAngled && model.angledView) {
      return this.angledView(model, zoom)
    }

    return null
  }

  topView(model) {
    return model.topViewResized
  }

  sideView(model, _zoom) {
    // if (zoom > 10) {
    //   return model.sideView
    // }

    // if (zoom > 7.9) {
    //   return model.sideViewXlarge
    // }

    // if (zoom > 3.9) {
    //   return model.sideViewLarge
    // }

    // if (zoom > 1.9) {
    //   return model.sideViewMedium
    // }

    return model.sideView
  }

  angledView(model) {
    return model.angledViewResized
  }

  extractHeightFromModel(model) {
    if (this.viewpointTop && model.topView) {
      return model.topViewHeight
    }

    if (this.viewpointSide && model.sideView) {
      return model.sideViewHeight
    }

    if (this.viewpointAngled && model.angledView) {
      return model.angledViewHeight
    }

    return null
  }

  extractWidthFromModel(model) {
    if (this.viewpointTop && model.topView) {
      return model.topViewWidth
    }

    if (this.viewpointSide && model.sideView) {
      return model.sideViewWidth
    }

    if (this.viewpointAngled && model.angledView) {
      return model.angledViewWidth
    }

    return null
  }

  imageHeight(model) {
    if (model.paint && (model.paint.topView || model.paint.sideView)) {
      const height = this.extractHeightFromModel(model.paint)
      if (height) {
        return height
      }
    }

    return this.extractHeightFromModel(model)
  }

  imageWidth(model) {
    if (model.paint && (model.paint.topView || model.paint.sideView)) {
      const width = this.extractWidthFromModel(model.paint)
      if (width) {
        return width
      }
    }

    return this.extractWidthFromModel(model)
  }
}
</script>

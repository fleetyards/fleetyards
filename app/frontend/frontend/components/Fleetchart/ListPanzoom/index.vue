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
            v-for="(columnItems, index) in fleetchartColumns"
            :key="`fleetchart-col-${index}`"
            name="fade-list"
            :appear="true"
            class="fleetchart-column"
          >
            <FleetchartItem
              v-for="item in columnItems"
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
                :src="require('@/images/community-logo.png')"
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

<script>
import { mapGetters } from 'vuex'
import panzoom from 'panzoom'
import Btn from '@/frontend/core/components/Btn/index.vue'
import BtnDropdown from '@/frontend/core/components/BtnDropdown/index.vue'
import DownloadScreenshotBtn from '@/frontend/components/DownloadScreenshotBtn/index.vue'
import FleetChartStatusBtn from '@/frontend/components/FleetChartStatusBtn/index.vue'
import debounce from 'lodash.debounce'
import Starship42Btn from '@/frontend/components/Starship42Btn/index.vue'
import FleetchartItem from './Item/index.vue'

export default {
  name: 'FleetchartListPanzoom',

  components: {
    Btn,
    BtnDropdown,
    DownloadScreenshotBtn,
    FleetchartItem,
    FleetChartStatusBtn,
    Starship42Btn,
  },

  props: {
    downloadName: {
      type: String,
      default: null,
    },

    items: {
      type: Array,
      default() {
        return []
      },
    },

    myShip: {
      type: Boolean,
      default: false,
    },

    namespace: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      checkReset: debounce(this.debouncedCheckReset, 300),
      fleetchartColumns: {},
      gridEnabled: false,
      gridSize: 80.0,
      innerMargin: 20,
      margin: 80,
      marginBottom: 40,
      markedForReset: false,
      maxZoom: 20,
      minZoom: 0.2,
      panzoomInstance: null,
      pinchSpeed: 3,
      screenHeight: null,
      screenHeightOptions: ['1x', '1_5x', '2x', '3x', '4x'],
      screenWidth: null,
      showStatus: false,
      sizeMultiplicator: 4,
      updateZoomData: debounce(this.debouncedUpdateZoomData, 300),
      viewpointOptions: ['side', 'top', 'angled'],
      zoomSpeed: 0.5,
    }
  },

  computed: {
    ...mapGetters(['mobile']),

    gridSizeLabel() {
      return (
        this.gridSize /
        (this.initialZoomData?.scale || 1) /
        this.sizeMultiplicator
      )
        .toFixed(2)
        .replace('.00', '')
    },

    initialZoomData() {
      return this.$store.getters[`${this.namespace}/fleetchartZoomData`]
    },

    maxColHeight() {
      return (
        this.screenHeight * this.screenHeightFactor -
        this.margin -
        this.marginBottom
      )
    },

    scale() {
      return this.initialZoomData?.scale || 1
    },

    screenHeightFactor() {
      return {
        '1_5x': 1.5,
        '1x': 1,
        '2x': 2,
        '3x': 3,
        '4x': 4,
      }[this.selectedScreenHeight]
    },

    selectedScreenHeight() {
      return this.$store.getters[`${this.namespace}/fleetchartScreenHeight`]
    },

    showLabels() {
      return this.$store.getters[`${this.namespace}/fleetchartLabels`]
    },

    viewpoint() {
      return this.$store.getters[`${this.namespace}/fleetchartViewpoint`]
    },

    viewpointAngled() {
      return this.viewpoint === 'angled'
    },

    viewpointSide() {
      return this.viewpoint === 'side'
    },

    viewpointTop() {
      return this.viewpoint === 'top'
    },
  },

  mounted() {
    this.showStatus = !!this.$route.query?.showStatus

    this.$comlink.$on('fleetchart-toggle-status', this.toggleStatus)

    this.updateScreenSize()

    this.setupColumns()

    this.setupZoom()

    window.addEventListener('resize', this.updateScreenSize)
    window.addEventListener('deviceorientation', this.updateScreenSize)
  },

  beforeDestroy() {
    this.$comlink.$off('fleetchart-toggle-status')

    this.panzoomInstance.dispose()

    this.panzoomInstance = null

    window.removeEventListener('resize', this.updateScreenSize)
    window.removeEventListener('deviceorientation', this.updateScreenSize)
  },

  methods: {
    angledView(model) {
      return model.angledViewResized
    },

    debouncedCheckReset() {
      if (this.markedForReset) {
        this.markedForReset = false

        this.resetZoom()
      }
    },

    debouncedUpdateZoomData() {
      const transform = this.panzoomInstance.getTransform()

      this.$store.commit(`${this.namespace}/setFleetchartZoomData`, transform)
    },

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
    },

    extractMaxHeightFromModel(model) {
      return Math.max(
        model.topViewHeight,
        model.sideViewHeight,
        model.angledViewHeight
      )
    },

    extractMaxWidthFromModel(model) {
      return Math.max(
        model.topViewWidth,
        model.sideViewWidth,
        model.angledViewWidth
      )
    },

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
    },

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
    },

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
    },

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
    },

    markForReset() {
      this.markedForReset = true

      setTimeout(() => {
        this.checkReset()
      }, 300)
    },

    modelName(item) {
      const model = item.model || item

      return model.name
    },

    productionStatus(item) {
      const model = item.model || item

      return this.$t(`labels.model.productionStatus.${model.productionStatus}`)
    },

    resetZoom() {
      this.panzoomInstance.zoomAbs(0, 0, 1)
      this.panzoomInstance.moveTo(0, 0)
    },

    setScreenHeight(screenHeight) {
      this.$store.commit(
        `${this.namespace}/setFleetchartScreenHeight`,
        screenHeight
      )

      this.setupColumns()
    },

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
    },

    async setupZoom() {
      this.panzoomInstance = panzoom(this.$refs.fleetchart, {
        maxZoom: this.maxZoom,
        minZoom: this.minZoom,
        pinchSpeed: this.pinchSpeed,
        zoomSpeed: this.zoomSpeed,
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
    },

    setViewpoint(viewpoint) {
      this.$store.commit(`${this.namespace}/setFleetchartViewpoint`, viewpoint)
    },

    sideView(model) {
      return model.sideViewResized
    },

    toggleGrid() {
      this.gridEnabled = !this.gridEnabled

      this.drawGridLines()
    },

    toggleLabels() {
      this.$store.commit(
        `${this.namespace}/setFleetchartLabels`,
        !this.showLabels
      )
    },

    toggleStatus() {
      this.showStatus = !this.showStatus
    },

    topView(model) {
      return model.topViewResized
    },

    updateScreenSize() {
      this.screenWidth = window.innerWidth
      this.screenHeight = window.innerHeight

      this.drawGridLines()
    },
  },
}
</script>

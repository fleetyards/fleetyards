<template>
  <div ref="modelViewer" class="holo-viewer">
    <BtnGroup :inline="true" class="actions">
      <Btn
        v-tooltip="autoRotateTooltip"
        size="small"
        variant="dropdown"
        :inline="true"
        :active="autoRotate"
        @click.native="toggleAutoRotate"
      >
        <i class="fal fa-planet-ringed" />
      </Btn>
      <Btn
        v-tooltip="zoomTooltip"
        size="small"
        variant="dropdown"
        :inline="true"
        :active="zoom"
        @click.native="toggleZoom"
      >
        <i class="fal fa-search-plus" />
      </Btn>
      <Btn
        v-if="colored"
        v-tooltip="colorTooltip"
        size="small"
        variant="dropdown"
        :inline="true"
        :active="color"
        @click.native="toggleColor"
      >
        <i class="fad fa-fill-drip" />
      </Btn>
    </BtnGroup>

    <Loader v-if="loading" :loading="loading" />
    <input v-if="debug" v-model="modelColor" type="color" />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import Loader from 'frontend/core/components/Loader'
import BtnGroup from 'frontend/core/components/BtnGroup'
import Btn from 'frontend/core/components/Btn'
import {
  WebGLRenderer,
  Scene,
  PerspectiveCamera,
  sRGBEncoding,
  PCFSoftShadowMap,
  DirectionalLight,
  DoubleSide,
  MeshPhongMaterial,
  Box3,
  Vector3,
} from 'three'
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js'
import { DRACOLoader } from 'three/examples/jsm/loaders/DRACOLoader.js'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'

@Component<HoloViewer>({
  components: {
    Loader,
    BtnGroup,
    Btn,
  },
})
export default class HoloViewer extends Vue {
  loading: boolean = false

  debug: boolean = false

  scene = null

  camera = null

  renderer = null

  model = null

  controls = null

  modelColor: number = 0x428bca

  windowColor: number = 0x1d3d59

  autoRotate: boolean = false

  autoRotateSpeed: number = 1.5

  zoom: boolean = false

  color: boolean = false

  @Prop({ required: true }) holo: string

  @Prop({ default: false }) colored: boolean

  get element() {
    return this.$refs.modelViewer
  }

  get elementWidth() {
    return this.element.clientWidth
  }

  get elementHeight() {
    return this.element.clientHeight
  }

  get autoRotateTooltip() {
    if (this.autoRotate) {
      return this.$t('actions.holoViewer.autoRotate.disable')
    }

    return this.$t('actions.holoViewer.autoRotate.enable')
  }

  get zoomTooltip() {
    if (this.zoom) {
      return this.$t('actions.holoViewer.zoom.disable')
    }

    return this.$t('actions.holoViewer.zoom.enable')
  }

  get colorTooltip() {
    if (this.color) {
      return this.$t('actions.holoViewer.color.disable')
    }

    return this.$t('actions.holoViewer.color.enable')
  }

  @Watch('modelColor')
  onModelColorChange() {
    this.updateModelMaterial()
  }

  @Watch('zoom')
  onZoomChange() {
    this.controls.enableZoom = this.zoom
    this.controls.update()
  }

  @Watch('color')
  onColorChange() {
    if (this.model) {
      this.updateModelMaterial()
    }
  }

  @Watch('autoRotate')
  onAutoRotateChange() {
    this.controls.autoRotate = this.autoRotate
    this.controls.update()
  }

  async mounted() {
    this.loading = true

    this.scene = this.setupScene()
    this.camera = this.setupCamera()
    this.scene.add(this.camera)
    this.renderer = this.setupRenderer()
    this.controls = this.setupControls(this.camera, this.renderer.domElement)

    this.loadModel()
  }

  animate() {
    this.controls.update()

    requestAnimationFrame(this.animate)

    this.renderer.render(this.scene, this.camera)
  }

  setupScene() {
    const scene = new Scene()

    scene.background = null

    return scene
  }

  setupCamera() {
    const camera = new PerspectiveCamera(
      35,
      this.elementWidth / this.elementHeight,
      1,
      1000
    )

    return camera
  }

  setupControls(camera, domElement) {
    const controls = new OrbitControls(camera, domElement)

    controls.enableDamping = true
    controls.dampingFactor = 0.25

    controls.enablePan = false

    controls.enableZoom = this.zoom
    controls.minDistance = 50
    controls.maxDistance = 250

    controls.autoRotate = this.autoRotate
    controls.autoRotateSpeed = this.autoRotateSpeed

    controls.listenToKeyEvents(window)

    controls.update()

    return controls
  }

  setupRenderer() {
    const renderer = new WebGLRenderer({
      antialias: true,
      alpha: true,
    })

    renderer.physicallyCorrectLights = true
    renderer.outputEncoding = sRGBEncoding
    renderer.setPixelRatio(window.devicePixelRatio)
    renderer.toneMappingExposure = 1
    renderer.setSize(this.elementWidth, this.elementHeight)
    renderer.shadowMap.enabled = true
    renderer.shadowMap.type = PCFSoftShadowMap

    this.element.appendChild(renderer.domElement)

    return renderer
  }

  setupDirectionalLight(model) {
    const directionalLight = new DirectionalLight(0x404040, 5)

    directionalLight.target = model
    directionalLight.castShadow = true

    return directionalLight
  }

  updateModelMaterial() {
    const material = new MeshPhongMaterial({
      color: this.modelColor,
      side: DoubleSide,
    })

    const windowMaterial = new MeshPhongMaterial({
      color: this.windowColor,
      side: DoubleSide,
    })

    this.model.traverse((node) => {
      if (!node.isMesh) return

      if (this.color) {
        if (node.backupMaterial) {
          node.material = node.backupMaterial
        }
      } else if (node.name.includes('window')) {
        node.backupMaterial = node.material
        node.material = windowMaterial
      } else {
        node.backupMaterial = node.material
        node.material = material
      }
    })
  }

  loadModel() {
    const loader = new GLTFLoader()

    const dracoLoader = new DRACOLoader()
    dracoLoader.setDecoderPath('/vendor/js/draco/')
    loader.setDRACOLoader(dracoLoader)

    loader.load(
      this.holo,
      (geometry) => {
        this.loading = false
        this.model = geometry.scene

        this.model.rotation.set(0, 45, 0)

        this.updateModelMaterial()

        this.scene.add(this.model)

        const box = new Box3().setFromObject(this.model)
        const size = box.getSize(new Vector3())

        const maxValue = Math.max(size.x, size.y)

        this.camera.position.set(0, 40, Math.max(maxValue * 1.2, size.y * 2))

        this.camera.add(this.setupDirectionalLight(this.model))

        this.animate()
      },
      null,
      (error) => {
        console.error(error)
      }
    )
  }

  toggleZoom() {
    this.zoom = !this.zoom
  }

  toggleColor() {
    this.color = !this.color
  }

  toggleAutoRotate() {
    this.autoRotate = !this.autoRotate
  }
}
</script>

<style lang="scss" scoped>
@import 'index.scss';
</style>

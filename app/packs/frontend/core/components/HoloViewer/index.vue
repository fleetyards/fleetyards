<template>
  <div ref="modelViewer" class="holo-viewer">
    <Loader v-if="loading" :loading="loading" />
    <input v-if="debug" v-model="modelColor" type="color" />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import Loader from 'frontend/core/components/Loader'
import {
  WebGLRenderer,
  Scene,
  PerspectiveCamera,
  sRGBEncoding,
  PCFSoftShadowMap,
  DirectionalLight,
  DoubleSide,
  MeshPhongMaterial,
} from 'three'
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js'
import { DRACOLoader } from 'three/examples/jsm/loaders/DRACOLoader.js'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import { Getter } from 'vuex-class'

@Component<HoloViewer>({
  components: {
    Loader,
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

  zoom: boolean = false

  @Prop({ required: true }) holo: string

  @Prop({ default: true }) autoRotate: boolean

  @Getter('mobile') mobile

  get element() {
    return this.$refs.modelViewer
  }

  get elementWidth() {
    return this.element.clientWidth
  }

  get elementHeight() {
    return this.element.clientHeight
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
    return new Scene()
  }

  setupCamera() {
    const camera = new PerspectiveCamera(
      35,
      this.elementWidth / this.elementHeight,
      1,
      1000,
    )

    if (this.mobile) {
      camera.position.set(0, 40, 80)
    } else {
      camera.position.set(0, 40, 70)
    }

    return camera
  }

  setupControls(camera, domElement) {
    const controls = new OrbitControls(camera, domElement)

    controls.enableDamping = true
    controls.dampingFactor = 0.25

    controls.enablePan = false

    controls.enableZoom = this.zoom
    controls.minDistance = 0
    controls.maxDistance = 200

    controls.autoRotate = this.autoRotate

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

    this.model.traverse(node => {
      if (!node.isMesh) return

      if (node.name.includes('custom_painted')) {
        // don't replace custom painted nodes
      } else if (node.name.includes('window')) {
        // don't replace window nodes
      } else {
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
      geometry => {
        this.loading = false
        this.model = geometry.scene

        this.updateModelMaterial()

        this.scene.add(this.model)

        this.camera.add(this.setupDirectionalLight(this.model))

        this.animate()
      },
      null,
      error => {
        console.error(error)
      },
    )
  }

  toggleZoom() {
    this.zoom = !this.zoom
  }
}
</script>

<style lang="scss" scoped>
.holo-viewer {
  position: absolute;
  top: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
}
</style>

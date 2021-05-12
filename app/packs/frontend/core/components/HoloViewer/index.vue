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

@Component<HoloViewer>({
  components: {
    Loader,
  },
})
export default class HoloViewer extends Vue {
  loading: boolean = false

  debug: boolean = false

  canvasPadding: number = 40

  scene = null

  camera = null

  renderer = null

  model = null

  controls = null

  modelColor: number = 0x428bca

  @Prop({ required: true }) holo: string

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

  async mounted() {
    this.loading = true

    this.scene = this.setupScene()
    this.camera = this.setupCamera(this.scene)
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

  setupCamera(scene) {
    const camera = new PerspectiveCamera(
      35,
      this.elementWidth / this.elementHeight,
      1,
      1e5,
    )
    camera.position.z = 70
    camera.lookAt(scene.position)

    return camera
  }

  setupControls(camera, domElement) {
    const controls = new OrbitControls(camera, domElement)

    controls.enableDamping = true
    controls.dampingFactor = 0.25
    controls.enableZoom = false
    controls.autoRotate = true
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
    renderer.setSize(
      this.elementWidth - this.canvasPadding,
      this.elementHeight - this.canvasPadding,
    )
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
      if (!node.isMesh || node.name.includes('custom_painted')) return

      node.material = material
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

        this.model.rotation.x -= 0.2

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

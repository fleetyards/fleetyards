<template>
  <div id="fileupload">
    <div
      v-if="isUploadActive"
      class="row fileupload-buttonbar"
    >
      <div class="col-lg-7">
        <VueUploadComponent
          ref="upload"
          v-model="newImages"
          :thread="3"
          :post-action="postAction"
          drop="body"
          :headers="headers"
          :data="metaData"
          multiple
          :add-index="true"
          @input-file="inputImage"
          @input-filter="inputFilter"
        />

        <Btn
          @click.native="selectImages"
        >
          <i class="fa fa-plus" />
          <span>{{ $t('labels.image.selectImages') }}</span>
        </Btn>

        <Btn
          @click.native="selectFolder"
        >
          <i class="fa fa-plus" />
          <span>{{ $t('labels.image.selectFolder') }}</span>
        </Btn>

        <Btn
          v-if="newImages.length"
          @click.native="startUpload"
        >
          <i class="fa fa-upload" />
          <span>{{ $t('labels.image.startUpload') }}</span>
        </Btn>

        <Btn
          v-if="newImages.length"
          @click.native="cancelUpload"
        >
          <i class="fa fa-ban-circle" />
          <span>{{ $t('labels.image.cancelUpload') }}</span>
        </Btn>
      </div>

      <div
        v-show="$refs.upload && $refs.upload.active"
        class="col-lg-5 fileupload-progress fade in"
      >
        <span class="fileupload-process">
          {{ speed | formatSize }}
        </span>

        <div class="progress">
          <div
            class="progress-bar progress-bar-animated progress-bar-info progress-bar-striped"
            role="progressbar"
            :style="{width: progress + '%'}"
          >
            {{ progress }} %
          </div>
        </div>
      </div>
    </div>

    <slot name="header" />

    <Panel
      v-if="isUploadActive"
      :variant="$refs.upload && $refs.upload.dropActive ? 'success' : null"
      @click.native="selectImages"
    >
      <div class="dropzone">
        <i class="fal fa-file-plus fa-2x" />
        <h3>
          {{ $t('labels.image.dropzone') }}
        </h3>
      </div>
    </Panel>

    <Panel v-if="allImages.length">
      <transition-group
        name="fade"
        class="flex-list"
        tag="div"
        appear
      >
        <div
          key="heading"
          class="fade-list-item col-xs-12 flex-list-heading"
        >
          <div class="flex-list-row">
            <div class="store-image wide" />

            <div class="description">
              {{ $t('labels.image.name') }}
            </div>

            <div class="size">
              {{ $t('labels.image.size') }}
            </div>

            <div class="actions" />
          </div>
        </div>

        <div
          v-for="image in allImages"
          :key="image.id"
          class="fade-list-item col-xs-12 flex-list-item"
        >
          <ImageRow
            :image="image"
            @start="startSingleUpload"
            @cancel="cancelSingleUpload"
            @imageDeleted="$emit('imageDeleted')"
          />
        </div>
      </transition-group>
    </Panel>

    <EmptyBox v-if="emptyBoxVisible" />

    <Loader
      :loading="loading"
      fixed
    />
  </div>
</template>

<script>
import VueUploadComponent from 'vue-upload-component'
import ImageRow from 'admin/components/ImageUploader/ImageRow'
import Loader from 'frontend/components/Loader'
import EmptyBox from 'frontend/partials/EmptyBox'
import Btn from 'frontend/components/Btn'
import Panel from 'frontend/components/Panel'

export default {
  name: 'ImageUploader',

  components: {
    Loader,
    VueUploadComponent,
    ImageRow,
    EmptyBox,
    Btn,
    Panel,
  },

  props: {
    images: {
      type: Array,
      required: true,
    },

    galleryId: {
      type: String,
      default: null,
    },

    galleryType: {
      type: String,
      default: null,
    },

    loading: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      newImages: [],
      postAction: `${window.API_ENDPOINT}/images`,
      uploadCount: 1,
      headers: {
        Accept: 'application/json',
        Authorization: `Bearer ${window.AUTH_TOKEN}`,
      },
    }
  },

  computed: {
    isUploadActive() {
      return !!this.galleryId && !!this.galleryType
    },

    allImages() {
      return [
        ...this.newImages,
        ...this.images,
      ]
    },

    metaData() {
      return {
        galleryId: this.galleryId,
        galleryType: this.galleryType,
      }
    },
    emptyBoxVisible() {
      return !this.loading && !this.allImages.length
    },
    activeImages() {
      return this.newImages.filter((item) => item.active)
    },
    progress() {
      if (!this.newImages.length) {
        return 0
      }

      const pendingProgress = this.newImages.map((item) => parseFloat(item.progress))
        .reduce((pv, cv) => pv + cv, 0)
      const completedUploads = this.uploadCount - this.newImages.length

      return Math.ceil((pendingProgress + (completedUploads * 100)) / this.uploadCount)
    },
    speed() {
      if (!this.activeImages.length) {
        return 0
      }

      return this.activeImages.map((item) => parseFloat(item.speed))
        .reduce((pv, cv) => pv + cv, 0) / this.activeImages.length
    },
  },

  mounted() {
    document.addEventListener('paste', this.addFileFromClipboard)
  },

  destroyed() {
    document.removeEventListener('paste')
  },

  methods: {
    addFileFromClipboard(event) {
      if (event.clipboardData && event.clipboardData.files.length > 0) {
        this.$refs.upload.add(event.clipboardData.files[0])
      }
    },

    selectImages() {
      this.$refs.upload.$el.querySelector('input').click()
    },

    selectFolder() {
      if (!this.$refs.upload.features.directory) {
        this.$alert({
          text: 'Your browser does not support',
        })

        return
      }
      const input = this.$refs.upload.$el.querySelector('input')
      input.directory = true
      input.webkitdirectory = true
      this.directory = true
      input.onclick = null
      input.click()
      input.onclick = (_e) => {
        this.directory = false
        input.directory = false
        input.webkitdirectory = false
      }
    },

    setUploadCount() {
      this.uploadCount = this.newImages.length
    },

    startUpload() {
      this.setUploadCount()
      this.$refs.upload.active = true
    },

    startSingleUpload(image) {
      this.$refs.upload.update(image, { active: true })
    },

    cancelUpload() {
      this.newImages = []
    },

    cancelSingleUpload(image) {
      this.$refs.upload.remove(image)
    },

    async inputImage(newImage, oldImage) {
      if (newImage && oldImage && !newImage.active && oldImage.active) {
        if (newImage.xhr && newImage.xhr.status === 200) {
          this.$emit('imageUploaded', newImage)
          const index = this.newImages.indexOf(newImage)
          this.newImages.splice(index, 1)
        }
      }
    },

    inputFilter(newImage, oldImage, prevent) {
      if (newImage && !oldImage) {
        if (!/\.(jpeg|jpe|jpg|gif|png|webp)$/i.test(newImage.name)) {
          prevent()
        }
      }

      if (!newImage) {
        return
      }

      /* eslint-disable no-param-reassign */
      newImage.blob = ''
      const URL = window.URL || window.webkitURL
      if (URL && URL.createObjectURL) {
        newImage.blob = URL.createObjectURL(newImage.file)
      }
      newImage.smallUrl = ''
      if (newImage.blob && newImage.type.substr(0, 6) === 'image/') {
        newImage.smallUrl = newImage.blob
      }
      /* eslint-enable no-param-reassign */
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'styles/index.scss';
</style>

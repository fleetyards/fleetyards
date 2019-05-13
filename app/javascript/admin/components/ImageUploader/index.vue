<template>
  <div id="fileupload">
    <div class="row fileupload-buttonbar">
      <div class="col-lg-7">
        <VueUploadComponent
          ref="upload"
          v-model="newFiles"
          :thread="3"
          :post-action="postAction"
          drop="#dropzone"
          :headers="headers"
          :data="uploadData"
          multiple
          :add-index="true"
          @input-file="inputFile"
          @input-filter="inputFilter"
        />
        <Btn
          @click.native="selectFiles"
        >
          <i class="fa fa-plus" />
          <span>Add files...</span>
        </Btn>
        <Btn
          @click.native="selectFolder"
        >
          <i class="fa fa-plus" />
          <span>Add a folder...</span>
        </Btn>
        <Btn
          v-if="newFiles.length"
          @click.native="startUpload"
        >
          <i class="fa fa-upload" />
          <span>Start upload</span>
        </Btn>
        <Btn
          v-if="newFiles.length"
          @click.native="cancelUpload"
        >
          <i class="fa fa-ban-circle" />
          <span>Cancel upload</span>
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

    <div
      id="dropzone"
      :class="{
        in: $refs.upload && $refs.upload.dropActive
      }"
      class="fade well drop-active"
    >
      <h3>
        Drop files here
      </h3>
    </div>
    <Panel v-if="allFiles.length">
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
              Name
            </div>
            <div class="size">
              File size
            </div>
            <div class="actions" />
          </div>
        </div>
        <div
          v-for="file in allFiles"
          :key="file.id"
          class="fade-list-item col-xs-12 flex-list-item"
        >
          <ImageRow
            :file="file"
            @start="startSingleUpload"
            @cancel="cancelSingleUpload"
            @fetch="fetch"
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
    galleryId: {
      type: String,
      required: true,
    },
    galleryType: {
      type: String,
      required: true,
    },
    fetchUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      files: [],
      newFiles: [],
      postAction: '/api/v1/images',
      uploadCount: 1,
      loading: true,
      headers: {
        Accept: 'application/json',
        Authorization: `Bearer ${window.AUTH_TOKEN}`,
      },
    }
  },
  computed: {
    allFiles() {
      return [
        ...this.newFiles,
        ...this.files,
      ]
    },
    emptyBoxVisible() {
      return !this.loading && !this.allFiles.length
    },
    uploadData() {
      return {
        galleryId: this.galleryId,
        galleryType: this.galleryType,
      }
    },
    activeFiles() {
      return this.newFiles.filter(item => item.active)
    },
    progress() {
      if (!this.newFiles.length) {
        return 0
      }

      const pendingProgress = this.newFiles.map(item => parseFloat(item.progress))
        .reduce((pv, cv) => pv + cv, 0)
      const completedUploads = this.uploadCount - this.newFiles.length

      return Math.ceil((pendingProgress + (completedUploads * 100)) / this.uploadCount)
    },
    speed() {
      if (!this.activeFiles.length) {
        return 0
      }

      return this.activeFiles.map(item => parseFloat(item.speed))
        .reduce((pv, cv) => pv + cv, 0) / this.activeFiles.length
    },
  },
  mounted() {
    this.fetch()
  },
  methods: {
    selectFiles() {
      this.$refs.upload.$el.querySelector('input').click()
    },
    selectFolder() {
      if (!this.$refs.upload.features.directory) {
        this.alert('Your browser does not support')
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
      this.uploadCount = this.newFiles.length
    },
    startUpload() {
      this.setUploadCount()
      this.$refs.upload.active = true
    },
    startSingleUpload(file) {
      this.$refs.upload.update(file, { active: true })
    },
    cancelUpload() {
      this.newFiles = []
    },
    cancelSingleUpload(file) {
      this.$refs.upload.remove(file)
    },
    async fetch() {
      this.loading = true

      const response = await this.$api.get(this.fetchUrl)

      this.loading = false
      if (!response.error) {
        this.files = response.data
      }
    },
    async inputFile(newFile, oldFile) {
      if (newFile && oldFile && !newFile.active && oldFile.active) {
        if (newFile.xhr && newFile.xhr.status === 200) {
          this.fetch()
          const index = this.newFiles.indexOf(newFile)
          this.newFiles.splice(index, 1)
        }
      }
    },
    inputFilter(newFile, oldFile, prevent) {
      if (newFile && !oldFile) {
        if (!/\.(jpeg|jpe|jpg|gif|png|webp)$/i.test(newFile.name)) {
          prevent()
        }
      }

      /* eslint-disable no-param-reassign */
      newFile.blob = ''
      const URL = window.URL || window.webkitURL
      if (URL && URL.createObjectURL) {
        newFile.blob = URL.createObjectURL(newFile.file)
      }
      newFile.smallUrl = ''
      if (newFile.blob && newFile.type.substr(0, 6) === 'image/') {
        newFile.smallUrl = newFile.blob
      }
      /* eslint-enable no-param-reassign */
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'styles/index.scss';
</style>

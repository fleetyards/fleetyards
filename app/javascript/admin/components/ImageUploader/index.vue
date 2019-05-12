<template>
  <div id="fileupload">
    <div class="row fileupload-buttonbar">
      <div class="col-lg-7">
        <VueUploadComponent
          ref="upload"
          v-model="files"
          :thread="3"
          :post-action="postAction"
          drop="#dropzone"
          :headers="headers"
          :data="uploadData"
          multiple
          class="btn btn-success fileinput-button"
          :add-index="true"
          @input-file="inputFile"
          @input-filter="inputFilter"
        >
          <i class="fa fa-plus" />
          <span>Add files...</span>
        </VueUploadComponent>
        <button
          v-if="pendingFiles.length"
          class="btn btn-primary start"
          @click.prevent="startUpload"
        >
          <i class="fa fa-upload" />
          <span>Start upload</span>
        </button>
        <button
          v-if="pendingFiles.length"
          class="btn btn-warning cancel"
          @click.prevent="cancelUpload"
        >
          <i class="fa fa-ban-circle" />
          <span>Cancel upload</span>
        </button>
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

    <div class="panel panel-default">
      <div class="table-responsive">
        <table
          class="table table-hover table-striped"
          role="presentation"
        >
          <thead>
            <tr>
              <th class="preview" />
              <th>
                Name
              </th>
              <th>
                File size
              </th>
              <th />
            </tr>
          </thead>
          <tbody>
            <ImageRow
              v-for="file in files"
              :key="file.id"
              :file="file"
              @start="startSingleUpload"
              @cancel="cancelSingleUpload"
              @fetch="fetch"
            />
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script>
import VueUploadComponent from 'vue-upload-component'
import ImageRow from 'admin/components/ImageUploader/ImageRow'

export default {
  name: 'ImageUploader',
  components: {
    VueUploadComponent,
    ImageRow,
  },
  data() {
    return {
      files: [],
      postAction: '/api/v1/images',
      uploadCount: 1,
      headers: {
        Accept: 'application/json',
        Authorization: `Bearer ${window.AUTH_TOKEN}`,
      },
    }
  },
  computed: {
    uuid() {
      return window.location.pathname.split('/')[2]
    },
    uploadData() {
      return {
        galleryId: this.uuid,
        galleryType: window.GALLERY_TYPE,
      }
    },
    pendingFiles() {
      return this.files.filter(item => !item.url)
    },
    activeFiles() {
      return this.files.filter(item => item.active)
    },
    progress() {
      if (!this.pendingFiles.length) {
        return 0
      }

      const pendingProgress = this.pendingFiles.map(item => parseFloat(item.progress))
        .reduce((pv, cv) => pv + cv, 0)
      const completedUploads = this.uploadCount - this.pendingFiles.length

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
    setUploadCount() {
      this.uploadCount = this.pendingFiles.length
    },
    startUpload() {
      this.setUploadCount()
      this.$refs.upload.active = true
    },
    startSingleUpload(file) {
      this.$refs.upload.update(file, { active: true })
    },
    cancelUpload() {
      this.fetch()
    },
    cancelSingleUpload(file) {
      this.$refs.upload.remove(file)
    },
    async fetch() {
      const response = await this.$api.get(`${window.GALLERY_PATH}/${this.uuid}/images`)

      if (!response.error) {
        this.files = response.data
      }
    },
    async inputFile(newFile, oldFile) {
      if (newFile && oldFile && !newFile.active && oldFile.active) {
        if (newFile.xhr && newFile.xhr.status === 200) {
          /* eslint-disable no-param-reassign */
          newFile.id = newFile.response.id
          newFile.url = newFile.response.url
          newFile.enabled = newFile.response.enabled
          newFile.background = newFile.response.background
          newFile.smallUrl = newFile.response.smallUrl
          /* eslint-enable no-param-reassign */
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

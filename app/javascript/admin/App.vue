<template>
  <div
    id="app"
    class="app-body container-fluid"
  >
    <ImageUploader
      :fetch-url="fetchUrl"
      :gallery-type="galleryType"
      :gallery-id="uuid"
    />
  </div>
</template>

<script>
import ImageUploader from 'admin/components/ImageUploader'

export default {
  name: 'AdminApp',
  components: {
    ImageUploader,
  },
  data() {
    return {
      galleryType: window.GALLERY_TYPE,
    }
  },
  computed: {
    uuid() {
      return window.location.pathname.split('/')[2]
    },
    fetchUrl() {
      return `${window.GALLERY_PATH}/${this.uuid}/images`
    },
  },
}
</script>

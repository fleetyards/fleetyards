<template>
  <div
    id="app"
    class="app-body container-fluid"
  >
    <ImageUploader />
  </div>
</template>

<script>
import ImageUploader from 'admin/components/ImageUploader'

export default {
  name: 'AdminApp',
  components: {
    ImageUploader,
  },
}
</script>

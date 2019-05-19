<template>
  <div class="row">
    <div class="col-xs-12">
      <div class="row">
        <div class="col-xs-12">
          <ImageUploader
            :loading="loading"
            :images="images"
            :gallery-id="uuid"
            gallery-type="Model"
            @imageDeleted="fetch"
            @imageUploaded="fetch"
          >
            <template #header>
              <div class="row">
                <div class="col-xs-12">
                  <Paginator
                    v-if="images.length"
                    :page="currentPage"
                    :total="totalPages"
                  />
                </div>
              </div>
            </template>
          </ImageUploader>
        </div>
      </div>
      <div class="row">
        <div class="col-xs-12">
          <Paginator
            v-if="images.length"
            :page="currentPage"
            :total="totalPages"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import ImageUploader from 'admin/components/ImageUploader'
import Pagination from 'frontend/mixins/Pagination'

export default {
  components: {
    ImageUploader,
  },
  mixins: [Pagination],
  data() {
    return {
      loading: true,
      images: [],
    }
  },
  computed: {
    uuid() {
      return this.$route.params.uuid
    },
  },
  watch: {
    $route() {
      this.fetch()
    },
  },
  mounted() {
    this.fetch()
  },
  methods: {
    async fetch() {
      this.loading = true

      const response = await this.$api.get(`models/${this.uuid}/images`, {
        page: this.$route.query.page,
      })

      this.loading = false
      if (!response.error) {
        this.images = response.data
      }
      this.setPages(response.meta)
    },
  },
}
</script>

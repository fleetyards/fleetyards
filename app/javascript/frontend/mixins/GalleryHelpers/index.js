import Gallery from 'frontend/components/Gallery'
import GalleryImage from 'frontend/components/GalleryImage'

export default {
  components: {
    Gallery,
    GalleryImage,
  },

  methods: {
    openGallery(index) {
      this.$refs.gallery.open(index)
    },
  },
}

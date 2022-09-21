<template>
  <div
    :key="`${backgroundImageKey}-${uuid}`"
    class="background-image"
    :class="{
      [backgroundImageKey]: true,
      webp: webpSupported,
    }"
  />
</template>

<script>
import axios from "axios";

export default {
  name: "BackgroundImage",

  data() {
    return {
      backgroundImageFallback: "bg-6",
      webpSupported: true,
    };
  },

  computed: {
    backgroundImageKey() {
      if (this.$route.meta.backgroundImage) {
        return this.$route.meta.backgroundImage;
      }

      return this.backgroundImageFallback;
    },

    uuid() {
      return this._uid;
    },
  },

  async created() {
    this.checkWebpSupport();
  },

  methods: {
    async checkWebpSupport() {
      if (typeof createImageBitmap === "undefined") {
        return false;
      }

      const webpData =
        "data:image/webp;base64,UklGRh4AAABXRUJQVlA4TBEAAAAvAAAAAAfQ//73v/+BiOh/AAA=";
      const response = await axios.get(webpData, { responseType: "blob" });

      this.webpSupported = await createImageBitmap(response.data).then(
        () => true,
        () => false
      );

      return this.webpSupported;
    },
  },
};
</script>

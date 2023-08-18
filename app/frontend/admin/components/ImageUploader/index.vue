<template>
  <div id="fileupload">
    <div v-if="isUploadActive" class="row fileupload-buttonbar">
      <div class="col-xl-7">
        <VueUploadComponent
          ref="upload"
          v-model="newImages"
          :custom-actions="upload"
          drop="body"
          :headers="headers"
          :data="metaData"
          multiple
          :add-index="true"
          @input-file="inputImage"
          @input-filter="inputFilter"
        />

        <Btn @click.native="selectImages">
          <i class="fa fa-plus" />
          {{ $t("labels.image.selectImages") }}
        </Btn>

        <Btn @click.native="selectFolder">
          <i class="fa fa-plus" />
          {{ $t("labels.image.selectFolder") }}
        </Btn>

        <Btn v-if="newImages.length" @click.native="startUpload">
          <i class="fa fa-upload" />
          {{ $t("labels.image.startUpload") }}
        </Btn>

        <Btn v-if="newImages.length" @click.native="cancelUpload">
          <i class="fa fa-ban" />
          {{ $t("labels.image.cancelUpload") }}
        </Btn>
      </div>

      <div
        v-show="$refs.upload && $refs.upload.active"
        class="col-xl-5 fileupload-progress fade in"
      >
        <span class="fileupload-process">
          {{ speed | formatSize }}
        </span>

        <div class="progress">
          <div
            class="progress-bar progress-bar-animated progress-bar-info progress-bar-striped"
            role="progressbar"
            :style="{ width: progress + '%' }"
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
          {{ $t("labels.image.dropzone") }}
        </h3>
      </div>
    </Panel>

    <Panel v-if="allImages.length">
      <transition-group name="fade" class="flex-list" tag="div" appear>
        <div key="heading" class="fade-list-item col-12 flex-list-heading">
          <div class="flex-list-row">
            <div class="store-image wide" />

            <div class="description">
              {{ $t("labels.image.name") }}
            </div>

            <div class="size">
              {{ $t("labels.image.size") }}
            </div>

            <div class="actions" />
          </div>
        </div>

        <div
          v-for="image in allImages"
          :key="image.id"
          class="fade-list-item col-12 flex-list-item"
        >
          <ImageRow
            :image="image"
            @start="startSingleUpload"
            @cancel="cancelSingleUpload"
            @image-deleted="$emit('image-deleted')"
          />
        </div>
      </transition-group>
    </Panel>

    <EmptyBox :visible="emptyBoxVisible" />

    <Loader :loading="loading" :fixed="true" />
  </div>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop } from "vue-property-decorator";
import VueUploadComponent from "vue-upload-component";
import Cookies from "js-cookie";
import Btn from "@/frontend/core/components/Btn/index.vue";
import { displayAlert } from "@/frontend/lib/Noty";
import Loader from "@/frontend/core/components/Loader/index.vue";
import EmptyBox from "@/frontend/core/components/EmptyBox/index.vue";
import Panel from "@/frontend/core/components/Panel/index.vue";
import ImageRow from "@/admin/components/ImageUploader/ImageRow/index.vue";

@Component<ImageUploader>({
  components: {
    Loader,
    VueUploadComponent,
    ImageRow,
    EmptyBox,
    Btn,
    Panel,
  },
})
export default class ImageUploader extends Vue {
  @Prop({ required: true }) images: Image[];

  @Prop({ default: null }) galleryId: string | null;

  @Prop({ default: null }) galleryType: string | null;

  @Prop({ default: false }) loading: boolean;

  newImages = [];

  postAction = `${window.ADMIN_API_ENDPOINT}/images`;

  uploadCount = 1;

  headers = {
    Accept: "application/json",
    "X-CSRF-Token": Cookies.get("COMMAND-CSRF-TOKEN"),
  };

  get isUploadActive() {
    return !!this.galleryId && !!this.galleryType;
  }

  get allImages() {
    return [...this.newImages, ...this.images];
  }

  get metaData() {
    return {
      galleryId: this.galleryId,
      galleryType: this.galleryType,
    };
  }

  get emptyBoxVisible() {
    return !this.loading && !this.allImages.length;
  }

  get activeImages() {
    return this.newImages.filter((item) => item.active);
  }

  get progress() {
    if (!this.newImages.length) {
      return 0;
    }

    const pendingProgress = this.newImages
      .map((item) => parseFloat(item.progress))
      .reduce((pv, cv) => pv + cv, 0);
    const completedUploads = this.uploadCount - this.newImages.length;

    return Math.ceil(
      (pendingProgress + completedUploads * 100) / this.uploadCount
    );
  }

  get speed() {
    if (!this.activeImages.length) {
      return 0;
    }

    return (
      this.activeImages
        .map((item) => parseFloat(item.speed))
        .reduce((pv, cv) => pv + cv, 0) / this.activeImages.length
    );
  }

  mounted() {
    document.addEventListener("paste", this.addFileFromClipboard);
  }

  destroyed() {
    document.removeEventListener("paste");
  }

  addFileFromClipboard(event) {
    if (event.clipboardData && event.clipboardData.files.length > 0) {
      this.$refs.upload.add(event.clipboardData.files[0]);
    }
  }

  selectImages() {
    this.$refs.upload.$el.querySelector("input").click();
  }

  selectFolder() {
    if (!this.$refs.upload.features.directory) {
      displayAlert({
        text: "Your browser does not support",
      });

      return;
    }

    const input = this.$refs.upload.$el.querySelector("input");
    input.directory = true;
    input.webkitdirectory = true;
    this.directory = true;
    input.onclick = null;
    input.click();
    input.onclick = (_e) => {
      this.directory = false;
      input.directory = false;
      input.webkitdirectory = false;
    };
  }

  setUploadCount() {
    this.uploadCount = this.newImages.length;
  }

  startUpload() {
    this.setUploadCount();
    this.$refs.upload.active = true;
  }

  startSingleUpload(image) {
    this.$refs.upload.update(image, { active: true });
  }

  cancelUpload() {
    this.newImages = [];
  }

  cancelSingleUpload(image) {
    this.$refs.upload.remove(image);
  }

  upload(file, component) {
    component.uploadHtml4(file);
  }

  async inputImage(newImage, oldImage) {
    if (newImage && oldImage && !newImage.active && oldImage.active) {
      if (newImage.xhr && newImage.xhr.status === 200) {
        this.$emit("image-uploaded", newImage);
        const index = this.newImages.indexOf(newImage);
        this.newImages.splice(index, 1);
      }
    }
  }

  inputFilter(newImage, oldImage, prevent) {
    if (newImage && !oldImage) {
      if (!/\.(jpeg|jpe|jpg|gif|png|webp)$/i.test(newImage.name)) {
        prevent();
      }
    }

    if (!newImage) {
      return;
    }

    /* eslint-disable no-param-reassign */
    newImage.blob = "";
    // eslint-disable-next-line compat/compat
    const URL = window.URL || window.webkitURL;
    if (URL && URL.createObjectURL) {
      newImage.blob = URL.createObjectURL(newImage.file);
    }
    newImage.smallUrl = "";
    if (newImage.blob && newImage.type.substr(0, 6) === "image/") {
      newImage.smallUrl = newImage.blob;
    }
    /* eslint-enable no-param-reassign */
  }
}
</script>

<style lang="scss" scoped>
@import "index.scss";
</style>

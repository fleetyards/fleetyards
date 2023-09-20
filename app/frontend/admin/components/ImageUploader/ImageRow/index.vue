<template>
  <div v-if="internalImage" class="flex-list-row">
    <div class="store-image wide">
      <a
        v-if="uploaded"
        :href="internalImage.url"
        :title="internalImage.name"
        :download="internalImage.name"
        target="_blank"
        rel="noopener"
      >
        <div
          :key="internalImage.smallUrl"
          v-lazy:background-image="internalImage.smallUrl"
          class="image lazy"
          alt="storeImage"
        />
      </a>
      <div
        v-else
        :key="internalImage.smallUrl"
        v-lazy:background-image="internalImage.smallUrl"
        class="image lazy"
        alt="storeImage"
      />
    </div>
    <div class="description">
      <h2>
        <a
          v-if="uploaded"
          :href="internalImage.url"
          :title="internalImage.name"
          :download="internalImage.name"
        >
          {{ internalImage.name }}
        </a>
        <span v-else>
          {{ internalImage.name }}
        </span>
        <FormInput
          v-if="uploaded"
          :id="`image-caption-${uuid}`"
          v-model="internalImage.caption"
          :no-label="true"
          placeholder="Caption"
          @input="updateCaption"
        />
      </h2>
      <div v-if="internalImage.error">
        <span class="pill pill-danger">
          {{ $t("labels.image.error") }}
        </span>
      </div>
      <template v-if="!uploaded">
        <p v-if="internalImage.active">
          {{ $t("labels.image.processing") }}
          {{ internalImage.speed | formatSize }}
        </p>
        <div
          v-if="internalImage.active || internalImage.progress !== '0.00'"
          class="progress"
        >
          <div
            class="progress-bar progress-bar-info progress-bar-striped"
            :class="{
              'progress-bar-danger': internalImage.error,
              'progress-bar-animated': internalImage.active,
            }"
            role="progressbar"
            :style="{ width: internalImage.progress + '%' }"
          >
            {{ internalImage.progress }} %
          </div>
        </div>
      </template>
    </div>
    <div class="size">
      {{ internalImage.size | formatSize }}
    </div>
    <div class="actions">
      <template v-if="uploaded">
        <Btn :disabled="updating" size="small" @click.native="toggleEnabled">
          <span v-show="internalImage.enabled">
            <i class="fa fa-check-square" />
          </span>
          <span v-show="!internalImage.enabled">
            <i class="far fa-square" />
          </span>
        </Btn>
        <Btn :disabled="updating" size="small" @click.native="toggleGlobal">
          <span v-show="internalImage.global">
            <i class="fas fa-globe" />
          </span>
          <span v-show="!internalImage.global">
            <i class="fal fa-globe icon-disabled" />
          </span>
        </Btn>
        <Btn :disabled="deleting" size="small" @click.native="deleteImage">
          <i class="fa fa-trash" />
          {{ $t("labels.image.delete") }}
        </Btn>
      </template>
      <template v-else>
        <Btn v-if="!internalImage.success" @click.native="start(internalImage)">
          <i class="fa fa-upload" />
          {{ $t("labels.image.start") }}
        </Btn>
        <Btn @click.native="cancel(internalImage)">
          <i class="fa fa-ban" />
          {{ $t("labels.image.cancel") }}
        </Btn>
      </template>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop, Watch } from "vue-property-decorator";
import Btn from "@/frontend/core/components/Btn/index.vue";
import debounce from "lodash.debounce";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import { useApiClient } from "@/admin/composables/useApiClient";

type Image = {
  id: string;
};

const { images: imagesService } = useApiClient();

@Component<ImageRow>({
  components: {
    Btn,
    FormInput,
  },
})
export default class ImageRow extends Vue {
  @Prop({ required: true }) image!: Image;

  deleting = false;

  updating = false;

  internalImage: Image = null;

  updateCaption = debounce(this.debouncedUpdateCaption, 500);

  get uuid() {
    return this._uid;
  }

  get uploaded() {
    return !!this.internalImage.url;
  }

  @Watch("image")
  onImageChange() {
    this.internalImage = this.image;
  }

  mounted() {
    this.internalImage = this.image;
  }

  start() {
    this.$emit("start", this.internalImage);
  }

  cancel() {
    this.$emit("cancel", this.internalImage);
  }

  async toggleEnabled() {
    this.updating = true;
    this.internalImage.enabled = !this.internalImage.enabled;

    try {
      await imagesService.updateImage({
        id: this.internalImage.id,
        requestBody: {
          enabled: this.internalImage.enabled,
        },
      });
    } catch (error) {
      console.error(error);
      this.internalImage.enabled = !this.internalImage.enabled;
    }

    this.updating = false;
  }

  async toggleGlobal() {
    this.updating = true;
    this.internalImage.global = !this.internalImage.global;

    try {
      await imagesService.updateImage({
        id: this.internalImage.id,
        requestBody: {
          enabled: this.internalImage.global,
        },
      });
    } catch (error) {
      console.error(error);
      this.internalImage.global = !this.internalImage.global;
    }

    this.updating = false;
  }

  async deleteImage() {
    this.deleting = true;

    try {
      await imagesService.destroy({
        id: this.internalImage.id,
      });

      this.$emit("image-deleted", this.internalImage);
    } catch (error) {
      console.error(error);
    }

    this.deleting = false;
  }

  async debouncedUpdateCaption() {
    this.updating = true;

    try {
      await imagesService.updateImage({
        id: this.internalImage.id,
        requestBody: {
          caption: this.internalImage.caption,
        },
      });
    } catch (error) {
      console.error(error);
    }

    this.updating = false;
  }
}
</script>

<style lang="scss" scoped>
@import "index";
</style>

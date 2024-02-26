<template>
  <div id="fileupload">
    <div v-if="isUploadActive" class="row fileupload-buttonbar">
      <div class="col-xl-7">
        <VueUploadComponent
          ref="uploadElement"
          v-model="newImages"
          post-action="/admin/images"
          drop="body"
          :headers="headers()"
          :data="metaData"
          multiple
          :add-index="true"
          @input-file="inputImage"
          @input-filter="inputFilter"
        />

        <Btn @click="selectImages">
          <i class="fa fa-plus" />
          {{ t("models.image.selectImages") }}
        </Btn>

        <Btn @click="selectFolder">
          <i class="fa fa-plus" />
          {{ t("models.image.selectFolder") }}
        </Btn>

        <Btn v-if="newImages.length" @click="startUpload">
          <i class="fa fa-upload" />
          {{ t("models.image.startUpload") }}
        </Btn>

        <Btn v-if="newImages.length" @click="cancelUpload">
          <i class="fa fa-ban" />
          {{ t("models.image.cancelUpload") }}
        </Btn>
      </div>

      <div
        v-show="uploadElement?.active"
        class="col-xl-5 fileupload-progress fade in"
      >
        <span class="fileupload-process">
          {{ formatSize(speed) }}
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
      :variant="uploadElement?.dropActive ? 'success' : undefined"
      slim
      @click="selectImages"
    >
      <div class="dropzone">
        <i class="fal fa-file-plus fa-2x" />
        <h3>
          {{ t("models.image.dropzone") }}
        </h3>
      </div>
    </Panel>

    <Panel v-if="allImages.length" slim>
      <transition-group name="fade" class="flex-list" tag="div" appear>
        <div key="heading" class="fade-list-item col-12 flex-list-heading">
          <div class="flex-list-row">
            <div class="store-image wide" />

            <div class="description">
              {{ t("models.image.name") }}
            </div>

            <div class="size">
              {{ t("models.image.size") }}
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

<script lang="ts" setup>
import VueUploadComponent from "vue-upload-component";
import type { VueUploadItem } from "vue-upload-component";
import { useNoty } from "@/shared/composables/useNoty";
import Btn from "@/shared/components/base/Btn/index.vue";
import EmptyBox from "@/shared/components/EmptyBox/index.vue";
import ImageRow from "@/admin/components/ImageUploader/ImageRow/index.vue";
import type { Image } from "@/services/fyAdminApi";
import Panel from "@/shared/components/Panel/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { useI18n } from "@/admin/composables/useI18n";
import { formatSize } from "@/shared/utils/Format";
import { csrfToken } from "@/shared/utils/Meta";

const { t } = useI18n();

const { displayAlert } = useNoty(t);

type Props = {
  images: Image[];
  galleryId?: string;
  galleryType?: string;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  galleryId: undefined,
  galleryType: undefined,
  loading: false,
});

const newImages = ref<VueUploadItem[]>([]);

const uploadCount = ref(0);

const uploadElement = ref<
  InstanceType<typeof VueUploadComponent> | undefined
>();

const headers = () => ({
  Accept: "application/json",
  "X-CSRF-Token": csrfToken(),
});

const isUploadActive = computed(() => {
  return !!props.galleryId && !!props.galleryType;
});

const allImages = computed(() => {
  return [...newImages.value, ...props.images];
});

const metaData = computed(() => {
  return {
    galleryId: props.galleryId,
    galleryType: props.galleryType,
  };
});

const emptyBoxVisible = computed(() => {
  return !props.loading && !allImages.value.length;
});

const activeImages = computed(() => {
  return newImages.value.filter((item) => item.active);
});

const progress = computed(() => {
  if (!newImages.value.length) {
    return 0;
  }

  const pendingProgress = newImages.value
    .map((item) => parseFloat(String(item.progress)))
    .reduce((pv, cv) => pv + cv, 0);
  const completedUploads = uploadCount.value - newImages.value.length;

  return Math.ceil(
    (pendingProgress + completedUploads * 100) / uploadCount.value,
  );
});

const speed = computed(() => {
  if (!activeImages.value.length) {
    return 0;
  }

  return (
    activeImages.value
      .map((item) => parseFloat(String(item.speed)))
      .reduce((pv, cv) => pv + cv, 0) / activeImages.value.length
  );
});

onMounted(() => {
  document.addEventListener("paste", addFileFromClipboard);
});

onUnmounted(() => {
  document.removeEventListener("paste", addFileFromClipboard);
});

const addFileFromClipboard = (event: ClipboardEvent) => {
  if (event.clipboardData && event.clipboardData.files.length > 0) {
    uploadElement.value?.add(event.clipboardData.files[0]);
  }
};

const selectImages = () => {
  uploadElement.value?.$el.querySelector("input").click();
};

const selectFolder = () => {
  if (!uploadElement.value?.features.directory) {
    displayAlert({
      text: "Your browser does not support",
    });

    return;
  }

  const input = uploadElement.value?.$el.querySelector("input");

  input.directory = true;
  input.webkitdirectory = true;
  input.onclick = null;
  input.click();

  input.onclick = (_e: Event) => {
    input.directory = false;
    input.webkitdirectory = false;
  };
};

const setUploadCount = () => {
  uploadCount.value = newImages.value.length;
};

const startUpload = () => {
  setUploadCount();
  if (uploadElement.value) {
    uploadElement.value.active = true;
  }
};

const startSingleUpload = (image: VueUploadItem) => {
  uploadElement.value?.update(image, { active: true });
};

const cancelUpload = () => {
  newImages.value = [];
};

const cancelSingleUpload = (image: VueUploadItem) => {
  uploadElement.value?.remove(image);
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const upload = async (
  file: VueUploadItem,
  component: typeof VueUploadComponent,
) => {
  return await component.uploadHtml4(file);
};

const emit = defineEmits(["image-uploaded", "image-deleted"]);

const inputImage = async (newImage: VueUploadItem, oldImage: VueUploadItem) => {
  if (newImage && oldImage && !newImage.active && oldImage.active) {
    if (newImage.xhr && newImage.xhr.status === 200) {
      emit("image-uploaded", newImage);

      const index = newImages.value.indexOf(newImage);

      newImages.value.splice(index, 1);
    }
  }
};

const inputFilter = (
  newImage: VueUploadItem,
  oldImage: VueUploadItem,
  prevent: (prevent?: boolean) => boolean,
) => {
  if (newImage && !oldImage) {
    if (!/\.(jpeg|jpe|jpg|gif|png|webp)$/i.test(String(newImage.name))) {
      prevent();
    }
  }

  if (!newImage) {
    return;
  }

  /* eslint-disable no-param-reassign */
  newImage.blob = "";
  const URL = window.URL || window.webkitURL;
  if (URL && URL.createObjectURL) {
    newImage.blob = URL.createObjectURL(newImage.file as Blob);
  }
  newImage.smallUrl = "";
  if (newImage.blob && newImage.type?.substring(0, 6) === "image/") {
    newImage.smallUrl = newImage.blob;
  }
  /* eslint-enable no-param-reassign */
};
</script>

<script lang="ts">
export default {
  name: "AdminImageUploader",
};
</script>

<style lang="scss" scoped>
@import "index.scss";
</style>

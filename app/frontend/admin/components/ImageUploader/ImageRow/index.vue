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
          v-model="internalImage.caption"
          :name="`image-caption-${uuid}`"
          :no-label="true"
          placeholder="Caption"
          @input="updateCaption"
        />
      </h2>
      <div v-if="(internalImage as VueUploadItem).error">
        <span class="pill pill-danger">
          {{ t("models.image.error") }}
        </span>
      </div>
      <template v-if="!uploaded">
        <p v-if="speed">
          {{ t("models.image.processing") }}
          {{ formatSize(speed) }}
        </p>
        <div
          v-if="
            (internalImage as VueUploadItem).active ||
            (internalImage as VueUploadItem).progress !== '0.00'
          "
          class="progress"
        >
          <div
            class="progress-bar progress-bar-info progress-bar-striped"
            :class="{
              'progress-bar-danger': (internalImage as VueUploadItem).error,
              'progress-bar-animated': (internalImage as VueUploadItem).active,
            }"
            role="progressbar"
            :style="{ width: (internalImage as VueUploadItem).progress + '%' }"
          >
            {{ (internalImage as VueUploadItem).progress }} %
          </div>
        </div>
      </template>
    </div>
    <div v-if="internalImage.size" class="size">
      {{ formatSize(internalImage.size) }}
    </div>
    <div class="actions">
      <template v-if="uploaded">
        <Btn :disabled="updating" size="small" @click="toggleEnabled">
          <span v-show="internalImage.enabled">
            <i class="fa fa-check-square" />
          </span>
          <span v-show="!internalImage.enabled">
            <i class="far fa-square" />
          </span>
        </Btn>
        <Btn :disabled="updating" size="small" @click="toggleGlobal">
          <span v-show="internalImage.global">
            <i class="fas fa-globe" />
          </span>
          <span v-show="!internalImage.global">
            <i class="fal fa-globe icon-disabled" />
          </span>
        </Btn>
        <Btn :disabled="deleting" size="small" @click="deleteImage">
          <i class="fa fa-trash" />
          {{ t("models.image.delete") }}
        </Btn>
      </template>
      <template v-else>
        <Btn v-if="!(internalImage as VueUploadItem).success" @click="start">
          <i class="fa fa-upload" />
          {{ t("models.image.start") }}
        </Btn>
        <Btn @click="cancel">
          <i class="fa fa-ban" />
          {{ t("models.image.cancel") }}
        </Btn>
      </template>
    </div>
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import debounce from "lodash.debounce";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { v4 as uuidv4 } from "uuid";
import { formatSize } from "@/shared/utils/Format";
import { useI18n } from "@/admin/composables/useI18n";
import type { Image } from "@/services/fyAdminApi";
import type { VueUploadItem } from "vue-upload-component";
import { useApiClient } from "@/admin/composables/useApiClient";

export interface UploadImage extends Image {
  progress?: string;
  active?: boolean;
  success?: boolean;
  error?: boolean;
  speed?: number;
}

type Props = {
  image: Image | VueUploadItem;
};

const props = defineProps<Props>();

const { t } = useI18n();

const deleting = ref(false);

const updating = ref(false);

const internalImage = ref<Image | VueUploadItem | undefined>();

const uuid = ref(uuidv4());

const uploaded = computed(() => {
  return !!internalImage.value?.url;
});

const speed = computed(() => {
  if (!(internalImage.value as VueUploadItem).speed) {
    return undefined;
  }

  return (internalImage.value as VueUploadItem).speed;
});

watch(
  () => props.image,
  () => {
    internalImage.value = props.image;
  },
);

onMounted(() => {
  uuid.value = uuidv4();
  internalImage.value = props.image;
});

const emit = defineEmits(["start", "cancel", "image-deleted"]);

const start = () => {
  emit("start", internalImage.value);
};

const cancel = () => {
  emit("cancel", internalImage.value);
};

const { images: imagesService } = useApiClient();

const toggleEnabled = async () => {
  if (!internalImage.value) {
    return;
  }

  updating.value = true;

  internalImage.value.enabled = !internalImage.value.enabled;

  try {
    await imagesService.updateImage({
      id: internalImage.value.id,
      requestBody: {
        enabled: internalImage.value.enabled,
      },
    });
  } catch (error) {
    console.error(error);
    internalImage.value.enabled = !internalImage.value.enabled;
  }

  updating.value = false;
};

const toggleGlobal = async () => {
  if (!internalImage.value) {
    return;
  }

  updating.value = true;

  internalImage.value.global = !internalImage.value.global;

  try {
    await imagesService.updateImage({
      id: internalImage.value.id,
      requestBody: {
        global: internalImage.value.global,
      },
    });
  } catch (error) {
    console.error(error);
    internalImage.value.global = !internalImage.value.global;
  }

  updating.value = false;
};

const deleteImage = async () => {
  if (!internalImage.value) {
    return;
  }

  deleting.value = true;

  try {
    await imagesService.destroy({
      id: internalImage.value.id,
    });

    emit("image-deleted", internalImage.value);
  } catch (error) {
    console.error(error);
  }

  deleting.value = false;
};

const debouncedUpdateCaption = async () => {
  if (!internalImage.value) {
    return;
  }

  updating.value = true;

  try {
    await imagesService.updateImage({
      id: internalImage.value.id,
      requestBody: {
        caption: internalImage.value.caption,
      },
    });
  } catch (error) {
    console.error(error);
  }

  updating.value = false;
};

const updateCaption = debounce(debouncedUpdateCaption, 500);
</script>

<script lang="ts">
export default {
  name: "ImageRow",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>

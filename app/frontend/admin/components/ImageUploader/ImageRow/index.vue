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
          {{ t("models.image.error") }}
        </span>
      </div>
      <template v-if="!uploaded">
        <p v-if="internalImage.active">
          {{ t("models.image.processing") }}
          {{ formatSize(internalImage.speed) }}
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
      {{ formatSize(internalImage.size) }}
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
          {{ t("models.image.delete") }}
        </Btn>
      </template>
      <template v-else>
        <Btn v-if="!internalImage.success" @click.native="start">
          <i class="fa fa-upload" />
          {{ t("models.image.start") }}
        </Btn>
        <Btn @click.native="cancel">
          <i class="fa fa-ban" />
          {{ t("models.image.cancel") }}
        </Btn>
      </template>
    </div>
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/BaseBtn/index.vue";
import debounce from "lodash.debounce";
import FormInput from "@/shared/components/Form/FormInput/index.vue";
import { v4 as uuidv4 } from "uuid";
import { formatSize } from "@/shared/utils/Format";
import { useI18n } from "@/admin/composables/useI18n";

export type Image = {
  id: string;
  name: string;
  url: string;
  size: number;
  progress: string;
  enabled: boolean;
  global: boolean;
  caption?: string;
  success?: boolean;
  active: boolean;
  error: boolean;
  speed: number;
  smallUrl: string;
};

type Props = {
  image: Image;
};

const props = defineProps<Props>();

const { t } = useI18n();

const deleting = ref(false);

const updating = ref(false);

const internalImage = ref<Image | undefined>();

const uuid = ref(uuidv4());

const uploaded = computed(() => {
  return !!internalImage.value?.url;
});

watch(
  () => props.image,
  () => {
    internalImage.value = props.image;
  }
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

const toggleEnabled = async () => {
  if (!internalImage.value) {
    return;
  }

  updating.value = true;

  internalImage.value.enabled = !internalImage.value.enabled;

  const response = await this.$api.put(`images/${internalImage.value.id}`, {
    enabled: internalImage.value.enabled,
  });

  updating.value = false;

  if (response.error) {
    internalImage.value.enabled = !internalImage.value.enabled;
  }
};

const toggleGlobal = async () => {
  if (!internalImage.value) {
    return;
  }

  updating.value = true;

  internalImage.value.global = !internalImage.value.global;

  const response = await this.$api.put(`images/${internalImage.value.id}`, {
    global: internalImage.value.global,
  });

  updating.value = false;

  if (response.error) {
    internalImage.value.global = !internalImage.value.global;
  }
};

const deleteImage = async () => {
  if (!internalImage.value) {
    return;
  }

  deleting.value = true;

  const response = await this.$api.destroy(`images/${internalImage.value.id}`);

  if (!response.error) {
    emit("image-deleted", internalImage.value);
  }

  deleting.value = false;
};

const debouncedUpdateCaption = async () => {
  if (!internalImage.value) {
    return;
  }

  updating.value = true;

  await this.$api.put(`images/${internalImage.value.id}`, {
    caption: internalImage.value.caption,
  });

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

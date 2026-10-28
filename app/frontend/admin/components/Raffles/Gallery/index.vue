<script lang="ts">
export default {
  name: "RaffleGallery",
};
</script>

<script lang="ts" setup>
import DirectUpload, {
  type FileUpload,
} from "@/shared/components/DirectUpload/index.vue";
import { fileTypeMap } from "@/shared/components/DirectUpload/types";
import { type MediaFile } from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";

type GalleryImage = {
  signedId: string;
  name: string;
  url?: string;
};

type Props = {
  images?: MediaFile[];
  disabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  images: () => [],
  disabled: false,
});

// The signed blob ids, in the order shown: what the form sends.
const emit = defineEmits<{
  "update:signedIds": [ids: string[]];
}>();

const { t } = useI18n();

const items = ref<GalleryImage[]>(
  props.images
    .filter((image) => !!image.signedId)
    .map((image) => ({
      signedId: image.signedId as string,
      name: image.name ?? "",
      url: image.smallUrl ?? image.url,
    })),
);

watch(
  items,
  () => {
    emit(
      "update:signedIds",
      items.value.map((item) => item.signedId),
    );
  },
  { deep: true },
);

const onUploadDone = (files: FileUpload[]) => {
  files.forEach((file) => {
    if (!file.blob) return;

    items.value.push({
      signedId: file.blob.signed_id,
      name: file.file.name,
      url: URL.createObjectURL(file.file),
    });
  });
};

const remove = (signedId: string) => {
  items.value = items.value.filter((item) => item.signedId !== signedId);
};
</script>

<template>
  <div class="raffle-gallery" data-test="raffle-gallery">
    <div class="field-label">{{ t("labels.raffle.images") }}</div>
    <ul v-if="items.length" class="raffle-gallery__list">
      <li
        v-for="(item, index) in items"
        :key="item.signedId"
        class="raffle-gallery__item"
      >
        <img :src="item.url" :alt="item.name" class="raffle-gallery__image" />
        <span v-if="index === 0" class="raffle-gallery__cover">
          {{ t("labels.raffle.cover") }}
        </span>
        <Btn
          v-if="!disabled"
          class="raffle-gallery__remove"
          tone="danger"
          size="sm"
          :aria-label="t('actions.delete')"
          @click="remove(item.signedId)"
        >
          <i class="fa-light fa-trash" />
        </Btn>
      </li>
    </ul>
    <DirectUpload
      v-if="!disabled"
      multiple
      inline
      :allowed-types="fileTypeMap.image"
      @upload:done="onUploadDone"
    />
    <p class="raffle-gallery__hint">{{ t("labels.raffle.imagesInfo") }}</p>
  </div>
</template>

<style lang="scss" scoped>
.raffle-gallery {
  margin-bottom: 1rem;
}

.raffle-gallery__list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 8px;
  margin: 0 0 8px;
  padding: 0;
  list-style: none;
}

.raffle-gallery__item {
  position: relative;
}

.raffle-gallery__image {
  display: block;
  width: 100%;
  aspect-ratio: 16 / 9;
  object-fit: cover;
  border-radius: 8px;
}

.raffle-gallery__cover {
  position: absolute;
  top: 6px;
  left: 6px;
  padding: 2px 6px;
  border-radius: 4px;
  background: rgba(0, 0, 0, 0.7);
  font-size: 0.75rem;
}

.raffle-gallery__remove {
  position: absolute;
  top: 6px;
  right: 6px;
}

.raffle-gallery__hint {
  font-size: 0.85rem;
  opacity: 0.8;
}
</style>

<script lang="ts">
export default {
  name: "VehicleEditModalImage",
};
</script>

<script lang="ts" setup>
import { useField } from "vee-validate";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Image,
  type ModelPaint,
  type Vehicle,
  FeatureFlagName,
  NullableVehiclePictureTypeEnum as PictureType,
  useModelImages,
  useVehiclePaints,
} from "@/services/fyApi";
import type { VehicleImageChanges } from "@/frontend/components/Vehicles/EditModal/types";
import { useFeatures } from "@/frontend/composables/useFeatures";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { value: image } = useField<string | null | undefined>("image");

// The stock render this picture replaces, so the field shows what an empty
// upload falls back to rather than a blank dropzone.
const stockImage = computed(
  () =>
    props.vehicle.upgrade?.media.storeImage?.smallUrl ||
    props.vehicle.model.media.storeImage?.smallUrl,
);

// Three ways to give the ship a picture: upload one, or pick one of the model's
// gallery pictures or paints. The upload wins where both are set, so picking
// one drops the upload -- otherwise the pick would save and change nothing
// anyone can see.
type Source = "upload" | "gallery" | "paints";

const initialSource = (): Source => {
  if (!props.vehicle.pictureId || props.vehicle.imageUploaded) return "upload";

  return props.vehicle.pictureType === PictureType.MODEL_PAINT
    ? "paints"
    : "gallery";
};

const source = ref<Source>(initialSource());

// Only an upload belongs in the upload field: `image` is the picked picture too.
const uploadedImage = computed(() =>
  props.vehicle.imageUploaded ? props.vehicle.image : undefined,
);

const GALLERY_PAGE_SIZE = "48";

const galleryPage = ref(1);

const { data: gallery, isLoading: galleryLoading } = useModelImages(
  () => props.vehicle.model.slug,
  () => ({ perPage: GALLERY_PAGE_SIZE, page: String(galleryPage.value) }),
);

// Pages add up, so a big gallery stays scrollable from its first picture.
const galleryImages = ref<Image[]>([]);

watch(
  gallery,
  (data) => {
    if (!data) return;

    const known = new Set(galleryImages.value.map((item) => item.id));
    galleryImages.value = [
      ...galleryImages.value,
      ...data.items.filter((item) => !known.has(item.id)),
    ];
  },
  { immediate: true },
);

const galleryHasMore = computed(() => {
  const pagination = gallery.value?.meta.pagination;

  return !!pagination && pagination.currentPage < pagination.totalPages;
});

const loadMoreGallery = () => {
  galleryPage.value += 1;
};

const { isFeatureEnabled } = useFeatures();

// Every paint of the model joins the gallery with its store image, owned or not:
// the picture is a look for the ship, not a record of what it owns. The
// vehicle's own list, because it keeps the current pick after the catalogue
// hides its paint, and lists owned paints first.
const { data: vehiclePaints } = useVehiclePaints(() => props.vehicle.id, {
  query: { enabled: isFeatureEnabled(FeatureFlagName.VEHICLE_OVERVIEW) },
});

const paintPictures = computed<ModelPaint[]>(() =>
  (vehiclePaints.value || [])
    .map((entry) => entry.paint)
    .filter((paint) => paint.media.storeImage),
);

type Pick = {
  type: NonNullable<VehicleImageChanges["pictureType"]>;
  id: string;
} | null;

const savedPick = (): Pick =>
  props.vehicle.pictureType && props.vehicle.pictureId
    ? { type: props.vehicle.pictureType, id: props.vehicle.pictureId }
    : null;

type PickSource = Exclude<Source, "upload">;

// Each pick segment keeps its own pick, and saving uses the open one's, so what
// is highlighted is what saves. A segment the saved picture is not from starts
// unset rather than on the standard picture, so merely opening it saves
// nothing.
const initialPick = (type: NonNullable<Pick>["type"]): Pick | undefined => {
  const saved = savedPick();

  return saved === null || saved.type === type ? saved : undefined;
};

const picks = reactive<Record<PickSource, Pick | undefined>>({
  gallery: initialPick(PictureType.IMAGE),
  paints: initialPick(PictureType.MODEL_PAINT),
});

const picked = computed(() =>
  source.value === "upload" ? undefined : picks[source.value],
);

const pick = (choice: Pick) => {
  if (source.value === "upload") return;

  picks[source.value] = choice;
};

const isPicked = (type: string, id: string) =>
  picked.value?.type === type && picked.value.id === id;

// A ship shows one picture of its own: saving a pick drops the upload, and an
// upload drops the pick.
const changes = (): VehicleImageChanges | undefined => {
  if (source.value !== "upload") {
    if (picked.value === undefined) return undefined;

    const saved = savedPick();
    if (
      !props.vehicle.imageUploaded &&
      picked.value?.type === saved?.type &&
      picked.value?.id === saved?.id
    ) {
      return undefined;
    }

    return {
      pictureType: picked.value?.type ?? null,
      pictureId: picked.value?.id ?? null,
      image: null,
    };
  }

  // `undefined` means the field was never touched, so there is nothing to save.
  if (image.value === undefined) return undefined;

  return {
    image: image.value,
    ...(props.vehicle.pictureId ? { pictureType: null, pictureId: null } : {}),
  };
};

defineExpose({ changes });
</script>

<template>
  <div>
    <BtnGroup segmented class="vehicle-edit-image__sources">
      <Btn
        :active="source === 'upload'"
        :aria-pressed="source === 'upload'"
        data-test="vehicle-image-source-upload"
        @click="source = 'upload'"
      >
        <i class="fa-duotone fa-upload" />
        {{ t("labels.vehicleOverview.pictureUpload") }}
      </Btn>
      <Btn
        :active="source === 'gallery'"
        :aria-pressed="source === 'gallery'"
        data-test="vehicle-image-source-gallery"
        @click="source = 'gallery'"
      >
        <i class="fa-duotone fa-images" />
        {{ t("labels.vehicleOverview.pictureGallery") }}
      </Btn>
      <Btn
        :active="source === 'paints'"
        :aria-pressed="source === 'paints'"
        data-test="vehicle-image-source-paints"
        @click="source = 'paints'"
      >
        <i class="fa-duotone fa-paint-roller" />
        {{ t("labels.vehicleLoadout.tabs.paints") }}
      </Btn>
    </BtnGroup>

    <FormFileInput
      v-if="source === 'upload'"
      v-model="image"
      :file="uploadedImage"
      :preview-src="uploadedImage ? undefined : stockImage"
      name="image"
      :label="t('labels.vehicleOverview.picture')"
      :info="t('labels.vehicleOverview.pictureInfo')"
      :allowed-types="AllowedFileTypes.IMAGE"
      clearable
    />
    <template v-else>
      <p v-if="vehicle.imageUploaded" class="vehicle-edit-image__hint">
        {{ t("texts.vehicleOverview.pickReplacesUpload") }}
      </p>
      <div
        v-if="source === 'paints'"
        class="vehicle-edit-image__gallery"
        data-test="vehicle-image-gallery-paints"
      >
        <button
          type="button"
          class="vehicle-edit-image__choice"
          :class="{
            'vehicle-edit-image__choice--picked': picked === null,
          }"
          :aria-pressed="picked === null"
          data-test="vehicle-image-gallery-none"
          @click="pick(null)"
        >
          <img
            v-if="stockImage"
            :src="stockImage"
            alt=""
            class="vehicle-edit-image__thumb"
          />
          <span class="vehicle-edit-image__caption">
            {{ t("labels.vehicleOverview.stockPicture") }}
          </span>
        </button>
        <button
          v-for="paint in paintPictures"
          :key="`paint-${paint.id}`"
          type="button"
          class="vehicle-edit-image__choice"
          :class="{
            'vehicle-edit-image__choice--picked': isPicked(
              PictureType.MODEL_PAINT,
              paint.id,
            ),
          }"
          :aria-pressed="isPicked(PictureType.MODEL_PAINT, paint.id)"
          :aria-label="paint.name"
          data-test="vehicle-image-gallery-paint"
          @click="pick({ type: PictureType.MODEL_PAINT, id: paint.id })"
        >
          <img
            :src="
              paint.media.storeImage?.smallUrl || paint.media.storeImage?.url
            "
            alt=""
            class="vehicle-edit-image__thumb"
          />
          <span class="vehicle-edit-image__caption">{{ paint.name }}</span>
        </button>
      </div>
      <template v-else>
        <div
          class="vehicle-edit-image__gallery"
          data-test="vehicle-image-gallery-images"
        >
          <button
            type="button"
            class="vehicle-edit-image__choice"
            :class="{
              'vehicle-edit-image__choice--picked': picked === null,
            }"
            :aria-pressed="picked === null"
            data-test="vehicle-image-gallery-none"
            @click="pick(null)"
          >
            <img
              v-if="stockImage"
              :src="stockImage"
              alt=""
              class="vehicle-edit-image__thumb"
            />
            <span class="vehicle-edit-image__caption">
              {{ t("labels.vehicleOverview.stockPicture") }}
            </span>
          </button>
          <button
            v-for="galleryImage in galleryImages"
            :key="galleryImage.id"
            type="button"
            class="vehicle-edit-image__choice"
            :class="{
              'vehicle-edit-image__choice--picked': isPicked(
                PictureType.IMAGE,
                galleryImage.id,
              ),
            }"
            :aria-pressed="isPicked(PictureType.IMAGE, galleryImage.id)"
            :aria-label="galleryImage.caption || vehicle.model.name"
            data-test="vehicle-image-gallery-choice"
            @click="pick({ type: PictureType.IMAGE, id: galleryImage.id })"
          >
            <img
              :src="galleryImage.smallUrl || galleryImage.url"
              alt=""
              class="vehicle-edit-image__thumb"
            />
          </button>
        </div>
        <p
          v-if="!galleryLoading && !galleryImages.length"
          class="vehicle-edit-image__hint"
        >
          {{ t("texts.vehicleOverview.galleryEmpty") }}
        </p>
        <Btn
          v-if="galleryHasMore"
          :loading="galleryLoading"
          block
          class="vehicle-edit-image__more"
          data-test="vehicle-image-gallery-more"
          @click="loadMoreGallery"
        >
          {{ t("actions.loadMore") }}
        </Btn>
      </template>
    </template>
  </div>
</template>

<style lang="scss" scoped>
.vehicle-edit-image {
  &__sources {
    margin-bottom: 15px;
  }

  &__hint {
    color: var(--color-text-dim);
    font-size: 0.85rem;
  }

  &__gallery {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
    gap: 8px;
    max-height: 420px;
    overflow-y: auto;
  }

  &__choice {
    position: relative;
    padding: 0;
    overflow: hidden;
    border: 2px solid var(--color-edge-soft);
    border-radius: 6px;
    background: var(--color-gray-black);
    color: inherit;
    cursor: pointer;

    &:hover,
    &:focus-visible {
      border-color: var(--color-edge-strong);
    }

    &--picked,
    &--picked:hover {
      border-color: var(--color-gold);
    }
  }

  &__more {
    margin-top: 8px;
  }

  &__thumb {
    display: block;
    width: 100%;
    height: 84px;
    object-fit: cover;
  }

  &__caption {
    position: absolute;
    right: 0;
    bottom: 0;
    left: 0;
    padding: 4px 8px;
    background: rgb(0 0 0 / 0.6);
    font-size: 0.75rem;
  }
}
</style>

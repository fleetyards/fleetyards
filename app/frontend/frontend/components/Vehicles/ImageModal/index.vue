<script lang="ts">
export default {
  name: "VehicleImageModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import {
  type FieldError,
  type Image,
  type Vehicle,
  type VehicleUpdateInput,
  useModelImages,
  useUpdateVehicle,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const { invalidateVehiclePage, invalidateHangarQueries } =
  useVehicleMutations();

const { defineField, handleSubmit } = useForm({
  initialValues: {
    image: undefined as string | null | undefined,
  },
});

const [image, imageProps] = defineField("image");

// The stock render this picture replaces, so the field shows what an empty
// upload falls back to rather than a blank dropzone.
const stockImage = computed(
  () =>
    props.vehicle.paint?.media.storeImage?.smallUrl ||
    props.vehicle.upgrade?.media.storeImage?.smallUrl ||
    props.vehicle.model.media.storeImage?.smallUrl,
);

// Two ways to give the ship a picture: upload one, or pick one of the model's
// own. The upload wins where both are set, so picking one drops the upload --
// otherwise the pick would save and change nothing anyone can see.
type Source = "upload" | "gallery";

const source = ref<Source>(
  props.vehicle.modelImageId && !props.vehicle.image ? "gallery" : "upload",
);

const GALLERY_PAGE_SIZE = "48";

const { data: gallery, isLoading: galleryLoading } = useModelImages(
  () => props.vehicle.model.slug,
  { perPage: GALLERY_PAGE_SIZE },
);

const galleryImages = computed<Image[]>(() => gallery.value?.items || []);

const pickedImageId = ref<string | null>(props.vehicle.modelImageId ?? null);

const pick = (imageId: string | null) => {
  pickedImageId.value = imageId;
};

// Not the hangar's optimistic update: that merges the request into the cached
// vehicle, and the request carries a signed blob id where the vehicle holds a
// file.
const { mutateAsync, isPending: submitting } = useUpdateVehicle();

const changes = (values: { image?: string | null }) => {
  if (source.value === "gallery") {
    if (pickedImageId.value === (props.vehicle.modelImageId ?? null)) {
      return undefined;
    }

    return { modelImageId: pickedImageId.value, image: null };
  }

  // `undefined` means the field was never touched, so there is nothing to save.
  return values.image === undefined ? undefined : { image: values.image };
};

const onSubmit = handleSubmit(async (values) => {
  const data: VehicleUpdateInput | undefined = changes(values);

  if (!data) {
    comlink.emit("close-modal");
    return;
  }

  await mutateAsync({
    id: props.vehicle.id,
    data,
  })
    .then(async (updatedVehicle) => {
      await Promise.all([
        invalidateVehiclePage(updatedVehicle),
        invalidateHangarQueries(),
      ]);

      displaySuccess({ text: t("messages.vehicleOverview.image.success") });
      comlink.emit("close-modal");
    })
    .catch((error: { response?: { data?: { errors?: FieldError[] } } }) => {
      // The attachment's own reason -- an SVG, say -- is what tells the owner
      // which file would work instead.
      const reason = error.response?.data?.errors?.find(
        (fieldError) => fieldError.attribute === "image",
      )?.messages[0]?.message;

      displayAlert({
        text: [t("messages.vehicleOverview.image.failure"), reason]
          .filter(Boolean)
          .join(": "),
      });
    });
});
</script>

<template>
  <Modal :title="t('headlines.vehicleOverview.picture')">
    <form id="vehicle-image-form" @submit.prevent="onSubmit">
      <BtnGroup segmented class="vehicle-image-modal__sources">
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
      </BtnGroup>

      <FormFileInput
        v-if="source === 'upload'"
        v-model="image"
        v-bind="imageProps"
        :file="vehicle.image"
        :preview-src="vehicle.image ? undefined : stockImage"
        name="image"
        :label="t('labels.vehicleOverview.picture')"
        :info="t('labels.vehicleOverview.pictureInfo')"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
      />

      <template v-else>
        <p v-if="vehicle.image" class="vehicle-image-modal__hint">
          {{ t("texts.vehicleOverview.galleryReplacesUpload") }}
        </p>
        <p
          v-if="!galleryLoading && !galleryImages.length"
          class="vehicle-image-modal__hint"
        >
          {{ t("texts.vehicleOverview.galleryEmpty") }}
        </p>
        <div v-else class="vehicle-image-modal__gallery">
          <button
            type="button"
            class="vehicle-image-modal__choice"
            :class="{
              'vehicle-image-modal__choice--picked': pickedImageId === null,
            }"
            :aria-pressed="pickedImageId === null"
            data-test="vehicle-image-gallery-none"
            @click="pick(null)"
          >
            <img
              v-if="stockImage"
              :src="stockImage"
              alt=""
              class="vehicle-image-modal__thumb"
            />
            <span class="vehicle-image-modal__caption">
              {{ t("labels.vehicleOverview.stockPicture") }}
            </span>
          </button>
          <button
            v-for="galleryImage in galleryImages"
            :key="galleryImage.id"
            type="button"
            class="vehicle-image-modal__choice"
            :class="{
              'vehicle-image-modal__choice--picked':
                pickedImageId === galleryImage.id,
            }"
            :aria-pressed="pickedImageId === galleryImage.id"
            :aria-label="galleryImage.caption || vehicle.model.name"
            data-test="vehicle-image-gallery-choice"
            @click="pick(galleryImage.id)"
          >
            <img
              :src="galleryImage.smallUrl || galleryImage.url"
              alt=""
              class="vehicle-image-modal__thumb"
            />
          </button>
        </div>
      </template>
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="vehicle-image-form"
        :loading="submitting"
        data-test="vehicle-image-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.vehicle-image-modal {
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

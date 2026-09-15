<script lang="ts">
export default {
  name: "HangarLogisticsInventoryModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { inventoryDefaultImage } from "@/frontend/composables/useInventoryImage";
import type { InventoryPanelRecord } from "@/frontend/types/logistics";
import {
  type HangarInventory,
  useCreateHangarInventory,
  useUpdateHangarInventory,
} from "@/services/fyApi";

type Props = {
  inventory?: HangarInventory;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const isEdit = computed(() => !!props.inventory);
const submitting = ref(false);

const validationSchema = {
  name: "required|min:2",
};

const { defineField, handleSubmit } = useForm({
  initialValues: {
    name: props.inventory?.name ?? "",
    description: props.inventory?.description ?? "",
    location: props.inventory?.location ?? "",
    image: undefined as string | undefined,
    imagePreset: props.inventory?.imagePreset ?? null,
  },
});

const [name, nameProps] = defineField("name");
const [description, descriptionProps] = defineField("description");
const [location, locationProps] = defineField("location");
const [image, imageProps] = defineField("image");
const [imagePreset] = defineField("imagePreset");

/*
 * What the field should show in place. `FormFileInput` draws an image from
 * `smallUrl`, which the serializer only emits for an attachment it could build
 * representations for -- so there are three cases, not two:
 *
 *   sized attachment  -> nothing here; the field draws it itself
 *   original only     -> the original, which is still the picture somebody
 *                        uploaded and must not be replaced by fallback art
 *   nothing attached  -> whatever the panel would fall back to
 */
const defaultImage = computed(() => {
  if (!props.inventory) return undefined;

  const image = props.inventory.image;

  if (image?.smallUrl) return undefined;
  if (image?.url) return image.url;

  return inventoryDefaultImage(props.inventory as InventoryPanelRecord);
});

const createMutation = useCreateHangarInventory();
const updateMutation = useUpdateHangarInventory();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data = {
    name: values.name,
    description: values.description || undefined,
    location: values.location || undefined,
    // Passed through rather than coerced: `undefined` keeps what is attached,
    // `null` is the field saying it was cleared, and a signed id replaces it.
    image: values.image,
    imagePreset: values.imagePreset,
  };

  const mutation = isEdit.value
    ? updateMutation.mutateAsync({ slug: props.inventory!.slug, data })
    : createMutation.mutateAsync({ data });

  await mutation
    .then(() => {
      displaySuccess({
        text: isEdit.value
          ? t("messages.logistics.inventory.update.success")
          : t("messages.logistics.inventory.create.success"),
      });
      comlink.emit(
        isEdit.value ? "hangar-inventory-updated" : "hangar-inventory-created",
      );
      comlink.emit("close-modal");
    })
    .catch(() => {
      displayAlert({
        text: isEdit.value
          ? t("messages.logistics.inventory.update.failure")
          : t("messages.logistics.inventory.create.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <Modal
    :title="
      isEdit
        ? t('headlines.logistics.editInventory')
        : t('headlines.logistics.createInventory')
    "
  >
    <form id="hangar-inventory-form" @submit.prevent="onSubmit">
      <!-- The picture already standing in for this inventory, so the field
           shows what it is replacing rather than an empty dropzone. See
           `defaultImage` for which of the three cases each is.

           No filter on the catalogue: an inventory is not a kind of thing the
           way a mission or a contract is, so there is nothing to narrow it by
           and every picture is offered at once. -->
      <FormFileInput
        v-model="image"
        v-model:preset-value="imagePreset"
        v-bind="imageProps"
        :file="inventory?.image"
        :preview-src="defaultImage"
        name="image"
        :label="t('labels.logistics.image')"
        :allowed-types="AllowedFileTypes.IMAGE"
        preset-catalogue="inventories"
        clearable
      />
      <FormInput
        v-model="name"
        v-bind="nameProps"
        name="name"
        translation-key="logistics.inventoryName"
        :rules="validationSchema.name"
        :label="t('labels.logistics.inventoryName')"
      />
      <FormTextarea
        v-model="description"
        v-bind="descriptionProps"
        name="description"
        translation-key="logistics.description"
        :label="t('labels.logistics.description')"
      />
      <FormInput
        v-model="location"
        v-bind="locationProps"
        name="location"
        translation-key="logistics.location"
        :label="t('labels.logistics.location')"
      />
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :loading="submitting"
          :size="BtnSizesEnum.LG"
          data-test="inventory-save"
          @click="onSubmit"
        >
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

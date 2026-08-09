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
  },
});

const [name, nameProps] = defineField("name");
const [description, descriptionProps] = defineField("description");
const [location, locationProps] = defineField("location");
const [image, imageProps] = defineField("image");

const createMutation = useCreateHangarInventory();
const updateMutation = useUpdateHangarInventory();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data = {
    name: values.name,
    description: values.description || undefined,
    location: values.location || undefined,
    image: values.image || undefined,
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
      <FormFileInput
        v-model="image"
        v-bind="imageProps"
        :file="inventory?.image"
        name="image"
        :label="t('labels.logistics.image')"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
      />
      <FormInput
        v-model="name"
        v-bind="nameProps"
        name="name"
        :rules="validationSchema.name"
        :label="t('labels.logistics.inventoryName')"
      />
      <FormTextarea
        v-model="description"
        v-bind="descriptionProps"
        name="description"
        :label="t('labels.logistics.description')"
      />
      <FormInput
        v-model="location"
        v-bind="locationProps"
        name="location"
        :label="t('labels.logistics.location')"
      />
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :loading="submitting"
          :size="BtnSizesEnum.LARGE"
          :inline="true"
          @click="onSubmit"
        >
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

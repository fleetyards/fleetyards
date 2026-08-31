<script lang="ts">
export default {
  name: "AdminEquipmentCreatePage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type EquipmentInput,
  useCreateEquipment,
  getEquipmentQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import ManufacturerFilterGroup from "@/admin/components/base/ManufacturerFilterGroup/index.vue";
import EquipmentSlotFilterGroup from "@/admin/components/base/EquipmentSlotFilterGroup/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useQueryClient } from "@tanstack/vue-query";

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const queryClient = useQueryClient();

const validationSchema = {
  name: "required",
};

const { defineField, handleSubmit, meta } = useForm<EquipmentInput>({
  validationSchema,
});

const [name, nameProps] = defineField("name");
const [equipmentType, equipmentTypeProps] = defineField("equipmentType");
const [itemType, itemTypeProps] = defineField("itemType");
const [subType, subTypeProps] = defineField("subType");
const [weaponClass, weaponClassProps] = defineField("weaponClass");
const [slot, slotProps] = defineField("slot");
const [size, sizeProps] = defineField("size");
const [grade, gradeProps] = defineField("grade");
const [manufacturerId, manufacturerIdProps] = defineField("manufacturerId");
const [description, descriptionProps] = defineField("description");
const [hidden, hiddenProps] = defineField("hidden");
const [scKey, scKeyProps] = defineField("scKey");
const [scRef, scRefProps] = defineField("scRef");
const [storeImage, storeImageProps] = defineField("storeImage");

const submitting = ref(false);

const createMutation = useCreateEquipment({
  mutation: {
    onSettled: () => {
      void queryClient.invalidateQueries({
        queryKey: getEquipmentQueryKey(),
      });
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await createMutation
    .mutateAsync({ data: values })
    .then(async (created) => {
      await router.push(
        extend({
          name: "admin-equipment-edit",
          params: { id: created.id },
        }),
      );
    })
    .catch((error) => {
      console.error("Error creating equipment:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(extend({ name: "admin-equipment" }));
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.equipment.new") }}</Heading>
  <form @submit.prevent="onSubmit" id="admin-equipment-create-form">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput v-model="name" v-bind="nameProps" name="name" />
        <FormTextarea
          v-model="description"
          v-bind="descriptionProps"
          name="description"
        />
        <ManufacturerFilterGroup
          v-model="manufacturerId"
          v-bind="manufacturerIdProps"
          :no-label="false"
          value-attr="id"
          :multiple="false"
          name="manufacturer"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="hidden"
          translation-key="equipment.hidden"
          v-bind="hiddenProps"
          name="hidden"
          align-with-fields
        />
        <hr />
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="equipmentType"
              v-bind="equipmentTypeProps"
              translation-key="equipment.equipmentType"
              name="equipmentType"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormInput
              v-model="itemType"
              v-bind="itemTypeProps"
              translation-key="equipment.itemType"
              name="itemType"
            />
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="subType"
              v-bind="subTypeProps"
              translation-key="equipment.subType"
              name="subType"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormInput
              v-model="weaponClass"
              v-bind="weaponClassProps"
              translation-key="equipment.weaponClass"
              name="weaponClass"
            />
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="size"
              v-bind="sizeProps"
              translation-key="equipment.size"
              name="size"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormInput
              v-model="grade"
              v-bind="gradeProps"
              translation-key="equipment.grade"
              name="grade"
            />
          </div>
        </div>
        <EquipmentSlotFilterGroup
          v-model="slot"
          v-bind="slotProps"
          :no-label="false"
          :multiple="false"
          name="slot"
        />
        <hr />
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="scKey"
              v-bind="scKeyProps"
              translation-key="equipment.scKey"
              name="scKey"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormInput
              v-model="scRef"
              v-bind="scRefProps"
              translation-key="equipment.scRef"
              name="scRef"
            />
          </div>
        </div>
        <hr />
        <FormFileInput
          v-model="storeImage"
          v-bind="storeImageProps"
          translation-key="equipment.storeImage"
          name="storeImage"
          :allowed-types="AllowedFileTypes.IMAGE"
          clearable
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      formId="admin-equipment-create-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>

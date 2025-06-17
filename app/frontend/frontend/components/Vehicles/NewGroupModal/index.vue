<script lang="ts">
export default {
  name: "VehiclesGroupModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import { VSwatches } from "vue3-swatches";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useCreateHangarGroup as useCreateHangarGroupMutation,
  HangarGroupCreateInput,
} from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { t } = useI18n();

const submitting = ref(false);

const validationSchema = {
  name: "required",
  color: "required",
};

const { defineField, handleSubmit } = useForm<HangarGroupCreateInput>();

const [name, nameProps] = defineField("name");
const [color, colorProps] = defineField("color");
const [publicField, publicFieldProps] = defineField("public");

const comlink = useComlink();

const mutation = useCreateHangarGroupMutation();

const { displayAlert } = useAppNotifications();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      data: values,
    })
    .then(() => {
      comlink.emit("hangar-group-save");
      comlink.emit("close-modal");
    })
    .catch((error) => {
      console.error(error);

      displayAlert({
        text: error.response.data.message,
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <Modal :title="t('headlines.hangarGroup.create')">
    <form id="hangar-group-new" @submit.prevent="onSubmit">
      <div class="row">
        <div class="col-12 col-md-6">
          <FormInput
            v-model="name"
            name="name"
            :rules="validationSchema.name"
            v-bind="nameProps"
            translation-key="name"
            :no-label="true"
          />
        </div>
        <div class="col-12 col-md-6">
          <FormInput
            v-model="color"
            name="color"
            :rules="validationSchema.color"
            v-bind="colorProps"
            translation-key="color"
            :no-label="true"
          />
        </div>
        <div class="col-12 col-md-6">
          <FormCheckbox
            v-model="publicField"
            name="public"
            v-bind="publicFieldProps"
            :label="t('labels.hangarGroup.public')"
          />
        </div>
        <div class="col-12">
          <VSwatches v-model="color" :inline="true" />
        </div>
      </div>
    </form>
    <template #footer>
      <div class="float-sm-right">
        <Btn
          form="hangar-group-new"
          :loading="submitting"
          type="submit"
          size="large"
          :inline="true"
        >
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

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
  useDestroyHangarGroup as useDestroyHangarGroupMutation,
  useUpdateHangarGroup as useUpdateHangarGroupMutation,
  HangarGroupUpdateInput,
  type HangarGroup,
} from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  hangarGroup: HangarGroup;
};

const props = defineProps<Props>();

const { t } = useI18n();

const submitting = ref(false);

const deleting = ref(false);

const validationSchema = {
  name: "required",
  color: "required",
};

const initialValues = ref<HangarGroupUpdateInput>({
  name: props.hangarGroup.name,
  color: props.hangarGroup.color,
  public: props.hangarGroup.public,
});

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
  validationSchema,
});

const [name, nameProps] = defineField("name");
const [color, colorProps] = defineField("color");
const [publicField, publicFieldProps] = defineField("public");

const setupForm = () => {
  initialValues.value = {
    name: props.hangarGroup?.name,
    color: props.hangarGroup?.color,
    public: props.hangarGroup?.public,
  };
};

onMounted(() => {
  setupForm();
});

watch(
  () => props.hangarGroup,
  () => {
    setupForm();
  },
  { deep: true },
);

const { displayAlert } = useAppNotifications();

const comlink = useComlink();

const destroyMutation = useDestroyHangarGroupMutation();

const onDestroy = async () => {
  deleting.value = true;

  await destroyMutation
    .mutateAsync({
      id: props.hangarGroup.id,
    })
    .then(() => {
      comlink.emit("hangar-group-delete", props.hangarGroup);
      comlink.emit("close-modal");
    })
    .then(() => {
      deleting.value = false;
    });
};

const updateMutation = useUpdateHangarGroupMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({
      id: props.hangarGroup.id,
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
  <Modal :title="t('headlines.hangarGroup.edit')">
    <form :id="`hangar-group-${hangarGroup.id}`" @submit.prevent="onSubmit">
      <div class="row">
        <div class="col-12 col-md-6">
          <FormInput
            v-model="name"
            name="name"
            v-bind="nameProps"
            translation-key="name"
            :no-label="true"
          />
        </div>
        <div class="col-12 col-md-6">
          <FormInput
            v-model="color"
            name="color"
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
          inline
          :confirm="t('messages.confirm.hangarGroup.destroy')"
          @click="onDestroy"
        >
          <i class="fal fa-trash" />
        </Btn>
        <Btn
          :form="`hangar-group-${hangarGroup.id}`"
          :loading="submitting"
          type="submit"
          size="large"
          inline
        >
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script lang="ts">
export default {
  name: "AdminComponentEditPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type Component,
  type ComponentInput,
  useUpdateComponent,
  getComponentsQueryKey,
  getComponentQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import ManufacturerFilterGroup from "@/admin/components/base/ManufacturerFilterGroup/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  component: Component;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const queryClient = useQueryClient();

const initialValues = ref<ComponentInput>({
  name: props.component.name,
  componentClass: props.component.class,
  componentType: props.component.type,
  componentSubType: props.component.subType,
  size: props.component.size,
  grade: props.component.grade,
  itemClass: undefined,
  itemType: undefined,
  manufacturerId: props.component.manufacturer?.id,
  description: undefined,
  hidden: props.component.hidden,
  scKey: props.component.scKey,
  scRef: props.component.scRef,
});

const validationSchema = {
  name: "required",
};

const { defineField, handleSubmit, meta } = useForm<ComponentInput>({
  initialValues: initialValues.value,
  validationSchema,
});

const [name, nameProps] = defineField("name");
const [componentClass, componentClassProps] = defineField("componentClass");
const [componentType, componentTypeProps] = defineField("componentType");
const [componentSubType, componentSubTypeProps] =
  defineField("componentSubType");
const [size, sizeProps] = defineField("size");
const [grade, gradeProps] = defineField("grade");
const [itemType, itemTypeProps] = defineField("itemType");
const [manufacturerId, manufacturerIdProps] = defineField("manufacturerId");
const [description, descriptionProps] = defineField("description");
const [hidden, hiddenProps] = defineField("hidden");
const [scKey, scKeyProps] = defineField("scKey");
const [scRef, scRefProps] = defineField("scRef");

const submitting = ref(false);

const updateMutation = useUpdateComponent({
  mutation: {
    onSettled: async () => {
      await queryClient.invalidateQueries({
        queryKey: getComponentsQueryKey(),
      });
      await queryClient.invalidateQueries({
        queryKey: getComponentQueryKey(props.component.id),
      });
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({ id: props.component.id, data: values })
    .catch((error) => {
      console.error("Error updating component:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(
    extend({
      name: "admin-components",
      hash: `#${props.component.id}`,
    }),
  );
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.components.edit") }}</Heading>
  <form @submit.prevent="onSubmit" id="admin-component-edit-form">
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
        <FormCheckbox
          v-model="hidden"
          translation-key="component.hidden"
          v-bind="hiddenProps"
          name="hidden"
        />
        <hr />
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="componentClass"
              v-bind="componentClassProps"
              translation-key="component.componentClass"
              name="componentClass"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormInput
              v-model="componentType"
              v-bind="componentTypeProps"
              translation-key="component.componentType"
              name="componentType"
            />
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="componentSubType"
              v-bind="componentSubTypeProps"
              translation-key="component.componentSubType"
              name="componentSubType"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormInput
              v-model="itemType"
              v-bind="itemTypeProps"
              translation-key="component.itemType"
              name="itemType"
            />
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="size"
              v-bind="sizeProps"
              translation-key="component.size"
              name="size"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormInput
              v-model="grade"
              v-bind="gradeProps"
              translation-key="component.grade"
              name="grade"
            />
          </div>
        </div>
        <hr />
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="scKey"
              v-bind="scKeyProps"
              translation-key="component.scKey"
              name="scKey"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormInput
              v-model="scRef"
              v-bind="scRefProps"
              translation-key="component.scRef"
              name="scRef"
            />
          </div>
        </div>
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      formId="admin-component-edit-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>

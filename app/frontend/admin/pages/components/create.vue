<script lang="ts">
export default {
  name: "AdminComponentCreatePage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type ComponentInput,
  useCreateComponent,
  getComponentsQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import ManufacturerFilterGroup from "@/admin/components/base/ManufacturerFilterGroup/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useQueryClient } from "@tanstack/vue-query";

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const queryClient = useQueryClient();

const validationSchema = {
  name: "required",
};

const { defineField, handleSubmit, meta } = useForm<ComponentInput>({
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

const createMutation = useCreateComponent({
  mutation: {
    onSettled: () => {
      void queryClient.invalidateQueries({
        queryKey: getComponentsQueryKey(),
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
          name: "admin-component-edit",
          params: { id: created.id },
        }),
      );
    })
    .catch((error) => {
      console.error("Error creating component:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(extend({ name: "admin-components" }));
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.components.new") }}</Heading>
  <form @submit.prevent="onSubmit" id="admin-component-create-form">
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
      formId="admin-component-create-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>

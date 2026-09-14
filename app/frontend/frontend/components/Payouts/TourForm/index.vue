<script lang="ts">
export default {
  name: "PayoutsTourForm",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useForm } from "vee-validate";
import { useI18n } from "@/shared/composables/useI18n";
import type { TourCreateInput } from "@/services/fyApi";

type Props = {
  submitting?: boolean;
};

withDefaults(defineProps<Props>(), { submitting: false });

const emit = defineEmits<{
  (event: "submit", values: TourCreateInput): void;
}>();

const { t } = useI18n();

const { defineField, handleSubmit } = useForm({
  initialValues: { title: "", description: "", startsAt: null },
});

const [title, titleProps] = defineField("title");
const [description, descriptionProps] = defineField("description");
const [startsAt, startsAtProps] = defineField("startsAt");

// FormDateTime emits a local "YYYY-MM-DDTHH:MM", which the schema's date-time
// format rejects.
const toIsoOrNull = (value: unknown) => {
  if (!value) return null;

  const parsed = new Date(value as string);

  return isNaN(parsed.getTime()) ? null : parsed.toISOString();
};

const onSubmit = handleSubmit((values) => {
  emit("submit", {
    title: values.title as string,
    description: (values.description as string) || null,
    startsAt: toIsoOrNull(values.startsAt),
  });
});
</script>

<template>
  <Panel>
    <PanelBody>
      <form id="tour-form" @submit.prevent="onSubmit">
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="title"
              name="title"
              rules="required"
              v-bind="titleProps"
              :label="t('labels.payouts.title')"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormDateTime
              v-model="startsAt"
              name="startsAt"
              v-bind="startsAtProps"
              :label="t('labels.payouts.startsAt')"
            />
          </div>
          <div class="col-12">
            <FormTextarea
              v-model="description"
              name="description"
              v-bind="descriptionProps"
              :label="t('labels.payouts.description')"
            />
          </div>
        </div>
      </form>
    </PanelBody>
  </Panel>

  <div class="tour-form-actions">
    <Btn
      :loading="submitting"
      :size="BtnSizesEnum.LG"
      data-test="tour-submit"
      @click="onSubmit"
    >
      {{ t("actions.save") }}
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
.tour-form-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}
</style>

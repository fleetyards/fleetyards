<script lang="ts">
export default {
  name: "TourAddPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useForm } from "vee-validate";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useCreateTour as useCreateTourMutation } from "@/services/fyApi";
import type { Crumb } from "@/shared/components/BreadCrumbs/types";
import type { ApiError } from "@/shared/types/api-error";

const { t } = useI18n();
const router = useRouter();
const { displaySuccess, displayAlert } = useAppNotifications();

const submitting = ref(false);

const { defineField, handleSubmit } = useForm({
  initialValues: { title: "", description: "", startsAt: null },
});

const [title, titleProps] = defineField("title");
const [description, descriptionProps] = defineField("description");
const [startsAt, startsAtProps] = defineField("startsAt");

const createMutation = useCreateTourMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await createMutation
    .mutateAsync({
      data: {
        title: values.title as string,
        description: (values.description as string) || null,
        startsAt: (values.startsAt as string | null) || null,
      },
    })
    .then((tour) => {
      displaySuccess({ text: t("messages.payouts.tourCreated") });
      void router.push({ name: "tour", params: { slug: tour.slug } });
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const crumbs = computed<Crumb[]>(() => [
  { to: { name: "tools" }, label: t("nav.tools.index") },
  { to: { name: "tours" }, label: t("nav.tools.tours") },
  { label: t("headlines.payouts.tours.create") },
]);
</script>

<template>
  <section class="container">
    <BreadCrumbs :crumbs="crumbs" />

    <Heading>{{ t("headlines.payouts.tours.create") }}</Heading>

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
      <Btn :loading="submitting" :size="BtnSizesEnum.LG" @click="onSubmit">
        {{ t("actions.save") }}
      </Btn>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.tour-form-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}
</style>

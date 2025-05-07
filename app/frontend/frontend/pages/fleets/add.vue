<script lang="ts">
export default {
  name: "FleetAddPage",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum, BtnTypesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { type FleetCreateInput, type ValidationError } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { transformErrors } from "@/frontend/api/helpers";
import { useCreateFleet as useCreateFleetMutation } from "@/services/fyApi";
import { AxiosError } from "axios";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const initialValues = ref<FleetCreateInput>({
  name: "",
  fid: "",
});

const validationSchema = {
  name: "required|min:3|alpha_dash",
  fid: "required|min:3|fidTaken|alpha_dash",
};

const { setErrors, handleSubmit } = useForm({
  initialValues,
  validationSchema,
});

const submitting = ref(false);

const router = useRouter();

const comlink = useComlink();

const mutation = useCreateFleetMutation();

const submit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      data: values.value,
    })
    .then((fleet) => {
      comlink.emit("fleet-create");

      displaySuccess({
        text: t("messages.fleet.create.success"),
      });

      router
        .push({
          name: "fleet",
          params: { slug: fleet.slug },
        })
        .catch(() => {});
    })
    .catch((error) => {
      const errorResponse = (error as AxiosError<ValidationError>).response
        ?.data;

      if (errorResponse?.errors) {
        setErrors(transformErrors(errorResponse.errors));
      }

      displayAlert({
        text: t("messages.fleet.create.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <section class="container">
    <form @submit.prevent="submit">
      <div class="row justify-content-lg-center">
        <div class="col-12 col-md-6 col-lg-4">
          <h1>{{ t("headlines.fleets.add") }}</h1>
        </div>
      </div>

      <div class="row justify-content-lg-center">
        <div class="col-12 col-md-6 col-lg-4">
          <FormInput name="fid" translation-key="fleet.fid" debounce />
          <FormInput name="name" translation-key="name" />
        </div>
      </div>
      <div class="row justify-content-lg-center">
        <div class="col-12 col-md-6 col-lg-4">
          <br />
          <Btn
            :loading="submitting"
            :type="BtnTypesEnum.SUBMIT"
            :size="BtnSizesEnum.LARGE"
            data-test="fleet-save"
          >
            {{ t("actions.save") }}
          </Btn>
        </div>
      </div>
    </form>
  </section>
</template>

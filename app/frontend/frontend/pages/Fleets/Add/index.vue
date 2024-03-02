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
          <FormInput name="fid" translation-key="fleet.fid" />
          <FormInput name="name" translation-key="name" />
        </div>
      </div>
      <div class="row justify-content-lg-center">
        <div class="col-12 col-md-6 col-lg-4">
          <br />
          <Btn
            :loading="submitting"
            type="submit"
            size="large"
            data-test="fleet-save"
          >
            {{ t("actions.save") }}
          </Btn>
        </div>
      </div>
    </form>
  </section>
</template>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { type FleetCreateInput, type ApiError } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { transformErrors } from "@/frontend/api/helpers";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useNoty(t);

const form = ref<Partial<FleetCreateInput>>({});

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

const { fleets: fleetsService } = useApiClient();

const router = useRouter();

const comlink = useComlink();

const submit = handleSubmit(async (values) => {
  submitting.value = true;

  try {
    const fleet = await fleetsService.createFleet({
      requestBody: values,
    });

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
  } catch (error) {
    const errorResponse = (error as ApiError).body;
    setErrors(transformErrors(errorResponse.errors));

    displayAlert({
      text: t("messages.fleet.create.failure"),
    });
  }

  submitting.value = false;
});
</script>

<script lang="ts">
export default {
  name: "FleetAddPage",
};
</script>

<script lang="ts">
export default {
  name: "FleetAddPage",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import { watchDebounced } from "@vueuse/core";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnTypesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import { type FleetCreateInput, checkFID } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useCreateFleet as useCreateFleetMutation } from "@/services/fyApi";
import { useSupportPrompt } from "@/shared/composables/useSupportPrompt";
import { useFleetStore } from "@/frontend/stores/fleet";
import { useSessionStore } from "@/frontend/stores/session";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const initialValues: FleetCreateInput = {
  name: "",
  fid: "",
  rsiSid: "",
};

const validationSchema = {
  name: "required|min:3|fleetName",
  fid: "required|min:3|fidTaken|alpha_dash",
};

const { setErrors, handleSubmit, values, setFieldValue } = useForm({
  initialValues,
});

// A taken FID shaped like an SID may be the reader's own RSI org, held by a
// fleet somebody else made: the answer then offers a free `X-N` to start with,
// and the org can claim `X` once its fleet is verified.
const takenFid = ref<string>();

const suggestion = ref<string>();

watchDebounced(
  () => values.fid,
  async (fid) => {
    takenFid.value = undefined;
    suggestion.value = undefined;

    if (!fid || fid.length < 3) return;

    const result = await checkFID({ value: fid }).catch(() => undefined);

    if (result?.taken && result.suggestion && values.fid === fid) {
      takenFid.value = fid.toUpperCase();
      suggestion.value = result.suggestion;
    }
  },
  { debounce: 300 },
);

const useSuggestion = () => {
  if (!suggestion.value || !takenFid.value) return;

  setFieldValue("rsiSid", takenFid.value);
  setFieldValue("fid", suggestion.value);
};

const submitting = ref(false);

const router = useRouter();

const comlink = useComlink();

const mutation = useCreateFleetMutation();

const supportPrompt = useSupportPrompt();

const fleetStore = useFleetStore();

const sessionStore = useSessionStore();

const submit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      data: values,
    })
    .then((fleet) => {
      comlink.emit("fleet-create");

      displaySuccess({
        text: t("messages.fleet.create.success"),
      });

      supportPrompt.notifyOnce("fleetCreated", "fleetCreated");

      const userId = sessionStore.currentUser?.id;

      if (userId) fleetStore.queueTour(userId, fleet.id);

      // A fleet started under a temporary FID goes on to verify its SID.
      router
        .push({
          name: fleet.rsiSid ? "fleet-settings-rsi" : "fleet",
          params: { slug: fleet.slug },
        })
        .catch(() => {});
    })
    .catch((error) => {
      const { formErrors } = validationErrorFrom(error);

      setErrors(formErrors);

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
      <div class="row lg:justify-center">
        <div class="col-12 col-md-6 col-lg-4">
          <h1>{{ t("headlines.fleets.add") }}</h1>
        </div>
      </div>

      <div class="row lg:justify-center">
        <div class="col-12 col-md-6 col-lg-4">
          <FormInput
            name="fid"
            :rules="validationSchema.fid"
            translation-key="fleet.fid"
          />
          <Alert
            v-if="suggestion && takenFid"
            :variant="AlertVariantsEnum.INFO"
            :title="
              t('labels.fleet.fidClaim.createTakenTitle', { fid: takenFid })
            "
            data-test="fleet-fid-suggestion"
          >
            {{
              t("labels.fleet.fidClaim.createTaken", {
                fid: takenFid,
                suggestion,
              })
            }}
            <template #actions>
              <Btn
                :size="BtnSizesEnum.SM"
                :variant="BtnVariantsEnum.BARE"
                data-test="fleet-fid-use-suggestion"
                @click="useSuggestion"
              >
                {{ t("actions.fleet.fidClaim.useSuggestion", { suggestion }) }}
                <i class="fa-light fa-chevron-right" />
              </Btn>
            </template>
          </Alert>
          <FormInput
            name="name"
            :rules="validationSchema.name"
            translation-key="name"
          />
          <FormInput
            name="rsiSid"
            icon="icon icon-rsi icon-label"
            translation-key="fleet.rsiSid"
          />
        </div>
      </div>
      <div class="row lg:justify-center">
        <div class="col-12 col-md-6 col-lg-4">
          <br />
          <Btn
            :loading="submitting"
            :type="BtnTypesEnum.SUBMIT"
            data-test="fleet-save"
            :size="BtnSizesEnum.LG"
          >
            {{ t("actions.save") }}
          </Btn>
        </div>
      </div>
    </form>
  </section>
</template>

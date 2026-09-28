<script lang="ts">
export default {
  name: "FleetRsiSettingsPage",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import FormInputGroup from "@/shared/components/base/FormInputGroup/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import { fidAtRisk } from "@/frontend/utils/rsiSid";
import {
  type Fleet,
  type FleetMember,
  type FleetUpdateInput,
  useUpdateFleet as useUpdateFleetMutation,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const comlink = useComlink();

const router = useRouter();

const route = useRoute();

const updateMutation = useUpdateFleetMutation();

const submitting = ref(false);

const validationSchema = {
  fid: "required|min:3|alpha_dash",
};

const { defineField, handleSubmit, meta, resetForm, setErrors } =
  useForm<FleetUpdateInput>({
    initialValues: {
      fid: props.fleet.fid,
      rsiSid: props.fleet.rsiSid,
    },
  });

const [fid, fidProps] = defineField("fid");
const [rsiSid, rsiSidProps] = defineField("rsiSid");

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({
      slug: route.params.slug as string,
      data: values,
    })
    .then(async (updatedFleet) => {
      displaySuccess({
        text: t("messages.fleet.update.success"),
      });

      // The saved values, not the typed ones: the SID comes back normalised.
      resetForm({
        values: { fid: updatedFleet.fid, rsiSid: updatedFleet.rsiSid },
      });

      comlink.emit("fleet-update");

      // The fleet ID is the fleet's address.
      if (updatedFleet.slug !== route.params.slug) {
        await router.replace({
          name: "fleet-settings-rsi",
          params: { slug: updatedFleet.slug },
        });
      }
    })
    .catch((error) => {
      const { message, formErrors } = validationErrorFrom(error);

      setErrors(formErrors);

      displayAlert({
        text: message || t("messages.fleet.update.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = () => {
  resetForm();
};

const showFidWarning = computed(() => fidAtRisk(props.fleet));

// The check reads the saved SID, so a typed one has to be saved first.
const canVerify = computed(
  () => !!props.fleet.rsiSid && rsiSid.value === props.fleet.rsiSid,
);

const openVerification = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/RsiVerificationModal/index.vue"),
    props: { fleet: props.fleet },
  });
};
</script>

<template>
  <Alert
    v-if="showFidWarning"
    :variant="AlertVariantsEnum.WARNING"
    data-test="fleet-fid-at-risk"
  >
    <strong>{{ t("labels.fleet.rsiVerification.fidAtRiskTitle") }}.</strong>
    {{ t("labels.fleet.rsiVerification.fidAtRisk", { fid: fleet.fid }) }}
    <template v-if="canVerify" #actions>
      <Btn
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.BARE"
        @click="openVerification"
      >
        {{ t("actions.fleet.rsiVerification.verify") }}
        <i class="fa-light fa-chevron-right" />
      </Btn>
    </template>
  </Alert>

  <form id="fleet-rsi-settings-form" @submit.prevent="onSubmit">
    <p class="text-muted">
      {{ t("labels.fleet.rsiSettings.hint") }}
    </p>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="fid"
          name="fid"
          :rules="validationSchema.fid"
          :label="t('labels.fleet.fid')"
          v-bind="fidProps"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInputGroup>
          <FormInput
            v-model="rsiSid"
            name="rsiSid"
            icon="icon icon-rsi icon-label"
            translation-key="fleet.rsiSid"
            v-bind="rsiSidProps"
          >
            <template #suffix>
              <a
                v-if="fleet.rsiVerified"
                :href="`https://robertsspaceindustries.com/orgs/${fleet.rsiSid}`"
                :aria-label="t('labels.fleet.rsiVerification.verified')"
                target="_blank"
                rel="noopener"
                data-test="fleet-rsi-sid-verified"
              >
                <i
                  v-tooltip="t('labels.fleet.rsiVerification.verified')"
                  class="fa-duotone fa-badge-check text-success"
                />
              </a>
              <i
                v-else
                v-tooltip="t('labels.fleet.rsiVerification.unverified')"
                :aria-label="t('labels.fleet.rsiVerification.unverified')"
                class="fa-duotone fa-circle-exclamation text-warning"
                data-test="fleet-rsi-sid-unverified"
              />
            </template>
          </FormInput>
          <Btn
            v-if="!fleet.rsiVerified"
            v-tooltip="
              canVerify
                ? undefined
                : t('labels.fleet.rsiVerification.saveFirst')
            "
            :size="BtnSizesEnum.SM"
            :disabled="!canVerify"
            data-test="fleet-rsi-verification-open"
            @click="openVerification"
          >
            {{ t("actions.fleet.rsiVerification.verify") }}
          </Btn>
        </FormInputGroup>
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      form-id="fleet-rsi-settings-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>

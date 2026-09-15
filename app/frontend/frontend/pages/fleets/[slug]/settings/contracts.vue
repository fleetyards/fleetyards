<script lang="ts">
export default {
  name: "FleetContractsSettingsPage",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import {
  type Fleet,
  type FleetMember,
  type FleetUpdateInput,
  FleetContractKindEnum,
  useUpdateFleet as useUpdateFleetMutation,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useContractCover } from "@/frontend/composables/useContractCover";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const router = useRouter();
const { resolve } = useContractCover();

const updateMutation = useUpdateFleetMutation();

const submitting = ref(false);

const { defineField, handleSubmit, meta, setErrors } =
  useForm<FleetUpdateInput>({
    initialValues: {
      transportContractCover: undefined,
      procurementContractCover: undefined,
      craftingContractCover: undefined,
    },
  });

const [transportContractCover, transportContractCoverProps] = defineField(
  "transportContractCover",
);
const [procurementContractCover, procurementContractCoverProps] = defineField(
  "procurementContractCover",
);
const [craftingContractCover, craftingContractCoverProps] = defineField(
  "craftingContractCover",
);

const fields = computed(() => [
  {
    kind: FleetContractKindEnum.TRANSPORT,
    name: "transportContractCover",
    model: transportContractCover,
    bind: transportContractCoverProps.value,
    file: props.fleet.contractCovers?.transport,
  },
  {
    kind: FleetContractKindEnum.PROCUREMENT,
    name: "procurementContractCover",
    model: procurementContractCover,
    bind: procurementContractCoverProps.value,
    file: props.fleet.contractCovers?.procurement,
  },
  {
    kind: FleetContractKindEnum.CRAFTING,
    name: "craftingContractCover",
    model: craftingContractCover,
    bind: craftingContractCoverProps.value,
    file: props.fleet.contractCovers?.crafting,
  },
]);

// What the board shows today for a kind with no art of its own, so a fleet can
// see what it would be replacing rather than guessing.
const fallbackFor = (kind: FleetContractKindEnum) =>
  resolve({ kind } as never, null);

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({ slug: props.fleet.slug, data: values })
    .then(() => {
      displaySuccess({ text: t("messages.fleet.update.success") });
      comlink.emit("fleet-update");
    })
    .catch((error) => {
      const { message, formErrors } = validationErrorFrom(error);

      setErrors(formErrors);

      displayAlert({ text: message || t("messages.fleet.update.failure") });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const cancel = () => {
  void router.push({
    name: "fleet-contracts",
    params: { slug: props.fleet.slug },
  });
};
</script>

<template>
  <form id="fleet-contract-settings-form" @submit.prevent="onSubmit">
    <Panel>
      <!-- A PanelHeading rather than a Heading inside the body, which is what
           the roles page beside it uses: the panel's own heading is Orbitron,
           and a body heading is the plain body face. -->
      <PanelHeading :level="HeadingLevelEnum.H3">
        {{ t("headlines.fleet.contractCovers") }}
      </PanelHeading>
      <PanelBody>
        <p class="contract-covers__lede">
          {{ t("texts.fleet.contractCovers") }}
        </p>

        <div class="row">
          <div
            v-for="field in fields"
            :key="field.name"
            class="col-12 col-md-4 contract-covers__field"
          >
            <!-- The art in use today. A fleet that has uploaded none sees the
                 built-in one it would be replacing. -->
            <img
              class="contract-covers__preview"
              :src="field.file?.mediumUrl || fallbackFor(field.kind)"
              alt=""
            />

            <FormFileInput
              v-model="field.model.value"
              v-bind="field.bind"
              :file="field.file"
              :name="field.name"
              :translation-key="`fleet.contractCovers.${field.kind}`"
              :allowed-types="AllowedFileTypes.IMAGE"
              clearable
            />
          </div>
        </div>
      </PanelBody>
    </Panel>

    <FormActions
      form-id="fleet-contract-settings-form"
      :submitting="submitting"
      :dirty="meta.dirty"
      @cancel="cancel"
    />
  </form>
</template>

<style lang="scss" scoped>
.contract-covers {
  &__lede {
    margin-bottom: 20px;
    color: $gray-light;
  }

  &__preview {
    display: block;
    width: 100%;
    height: 110px;
    object-fit: cover;
    border-radius: $panelContentBorderRadius;
    margin-bottom: 10px;
  }
}
</style>

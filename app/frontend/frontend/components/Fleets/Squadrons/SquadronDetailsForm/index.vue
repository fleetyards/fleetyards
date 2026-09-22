<script lang="ts">
export default {
  name: "FleetSquadronDetailsForm",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { VSwatches } from "vue3-swatches";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type FleetSquadron,
  useCreateFleetSquadron,
  useUpdateFleetSquadron,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  // Absent when the squadron is being created. Its pictures cannot be uploaded
  // until it exists, which is why they are a tab of their own on the editor
  // rather than a second half of this form.
  squadron?: FleetSquadron;
};

const props = withDefaults(defineProps<Props>(), { squadron: undefined });

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const router = useRouter();

const isEdit = computed(() => !!props.squadron);

const submitting = ref(false);

// The API's own limits. Drawn under each field as a running count, so the
// length is something the author sees while writing rather than on a save the
// server turns down.
const SHORT_DESCRIPTION_MAX = 255;
const DESCRIPTION_MAX = 5000;

const validationSchema = {
  name: "required|min:2|max:255",
  // What the card carries, so it stays short.
  shortDescription: `max:${SHORT_DESCRIPTION_MAX}`,
  description: `max:${DESCRIPTION_MAX}`,
};

const { defineField, handleSubmit, setErrors, meta } = useForm({
  initialValues: {
    name: props.squadron?.name ?? "",
    shortDescription: props.squadron?.shortDescription ?? "",
    description: props.squadron?.description ?? "",
    // The picker cannot express "no colour", so a squadron without one opens on
    // the neutral it is already drawn with rather than on the browser's black.
    color: props.squadron?.color ?? "#8899aa",
  },
});

const [name, nameProps] = defineField("name");
const [shortDescription, shortDescriptionProps] =
  defineField("shortDescription");
const [description, descriptionProps] = defineField("description");
const [color, colorProps] = defineField("color");

const createMutation = useCreateFleetSquadron();
const updateMutation = useUpdateFleetSquadron();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data = {
    name: values.name,
    shortDescription: values.shortDescription || null,
    description: values.description || null,
    color: values.color || null,
  };

  const request = isEdit.value
    ? updateMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        slug: props.squadron!.slug,
        data,
      })
    : createMutation.mutateAsync({ fleetSlug: props.fleet.slug, data });

  await request
    .then((saved) => {
      displaySuccess({
        text: isEdit.value
          ? t("messages.fleet.squadrons.update.success")
          : t("messages.fleet.squadrons.create.success"),
      });
      comlink.emit(
        isEdit.value ? "fleet-squadron-updated" : "fleet-squadron-created",
      );

      // A new squadron opens on its pictures, which is the half that could not
      // be filled in until it existed. An edit goes back to the squadron.
      void router.push(
        isEdit.value
          ? {
              name: "fleet-squadron",
              params: { slug: props.fleet.slug, squadron: saved.slug },
            }
          : {
              name: "fleet-squadron-edit-images",
              params: { slug: props.fleet.slug, squadron: saved.slug },
            },
      );
    })
    .catch((error) => {
      const { message, formErrors } = validationErrorFrom(error);

      setErrors(formErrors);

      displayAlert({
        text:
          message ||
          (isEdit.value
            ? t("messages.fleet.squadrons.update.failure")
            : t("messages.fleet.squadrons.create.failure")),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = () => {
  void router.push(
    props.squadron
      ? {
          name: "fleet-squadron",
          params: { slug: props.fleet.slug, squadron: props.squadron.slug },
        }
      : { name: "fleet-squadrons", params: { slug: props.fleet.slug } },
  );
};
</script>

<template>
  <form id="fleet-squadron-details-form" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="name"
          v-bind="nameProps"
          name="name"
          :rules="validationSchema.name"
          :label="t('labels.fleet.squadrons.name')"
        />
      </div>
    </div>

    <!-- The picker beside the field it writes into rather than under it: the
         swatches are the quick way to answer the input, not a second question. -->
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="color"
          v-bind="colorProps"
          name="color"
          :type="InputTypesEnum.COLOR"
          :label="t('labels.fleet.squadrons.color')"
        />
      </div>
      <div class="col-12 col-md-6">
        <VSwatches v-model="color" :inline="true" />
      </div>
    </div>

    <hr />

    <div class="row">
      <div class="col-12">
        <FormTextarea
          v-model="shortDescription"
          v-bind="shortDescriptionProps"
          name="shortDescription"
          :rules="validationSchema.shortDescription"
          :maxlength="SHORT_DESCRIPTION_MAX"
          :label="t('labels.fleet.squadrons.shortDescription')"
          :info="t('labels.fleet.squadrons.shortDescriptionHint')"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12 squadron-description-field">
        <FormTextarea
          v-model="description"
          v-bind="descriptionProps"
          name="description"
          :rules="validationSchema.description"
          :maxlength="DESCRIPTION_MAX"
          :label="t('labels.fleet.squadrons.description')"
          :info="t('labels.fleet.squadrons.descriptionHint')"
        />
      </div>
    </div>

    <FormActions
      :submitting="submitting"
      form-id="fleet-squadron-details-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>

<style lang="scss" scoped>
// Taller than the default textarea: this is the page's prose, and the
// description of a squadron opening at the same three lines as its one-line
// card subtitle read as though it wanted the same answer.
.squadron-description-field :deep(textarea) {
  min-height: 260px;
}
</style>

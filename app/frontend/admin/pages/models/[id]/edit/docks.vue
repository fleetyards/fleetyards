<script lang="ts">
export default {
  name: "AdminModelEditDocksPage",
};
</script>

<script lang="ts" setup>
import DocksEditor from "@/admin/components/Docks/Editor/index.vue";
import ModelForm from "@/admin/components/Models/Form/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type ModelExtended,
  type ModelUpdateInput,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";

interface Props {
  model: ModelExtended;
}

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

// The game names none of these areas, so each gets the name the ship page
// shows for it here. The game's own shape name stands in as the placeholder.
const servicingAreas = computed(() => props.model.servicingAreas ?? []);

const areaNames = () => ({
  servicingAreaNames: servicingAreas.value.map((area) => ({
    key: area.key,
    name: area.name ?? "",
  })),
});

const { handleSubmit, meta, resetForm } = useForm<ModelUpdateInput>({
  initialValues: areaNames(),
});

// The inputs bind by position, so a reload that adds or reorders areas has to
// rebuild the values they bind to, or a name lands on another area's key.
watch(
  () =>
    servicingAreas.value
      .map((area) => `${area.key}=${area.name ?? ""}`)
      .join("|"),
  () => resetForm({ values: areaNames() }),
);

const placeholder = (key: string) => key.split("#").pop();
</script>

<template>
  <DocksEditor
    :parent-id="model.id"
    parent-type="Model"
    :headline="t('headlines.admin.models.edit.docks')"
  />

  <template v-if="servicingAreas.length">
    <Heading hero>
      {{ t("headlines.admin.models.edit.servicingAreas") }}
    </Heading>
    <ModelForm :model="model" :handle-submit="handleSubmit" :meta="meta">
      <FormInput
        v-for="(area, index) in servicingAreas"
        :key="area.key"
        :name="`servicingAreaNames[${index}].name`"
        :label="`${toNumber(area.length)} × ${toNumber(area.width)} × ${toNumber(area.height)} m`"
        :placeholder="placeholder(area.key)"
        :data-test="`servicing-area-${index}`"
      />
    </ModelForm>
  </template>
</template>

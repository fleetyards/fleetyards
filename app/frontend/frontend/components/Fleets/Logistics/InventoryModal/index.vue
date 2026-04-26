<script lang="ts">
export default {
  name: "FleetLogisticsInventoryModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type FleetInventory,
  type FleetMember,
  type FilterOption,
  fleetMembers as fetchFleetMembers,
  useCreateFleetInventory,
  useUpdateFleetInventory,
} from "@/services/fyApi";
import { type FilterGroupParams } from "@/shared/components/base/FilterGroup/index.vue";

type Props = {
  fleet: Fleet;
  inventory?: FleetInventory;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const isEdit = computed(() => !!props.inventory);
const submitting = ref(false);

const validationSchema = {
  name: "required|min:2",
};

const { defineField, handleSubmit } = useForm({
  initialValues: {
    name: props.inventory?.name ?? "",
    description: props.inventory?.description ?? "",
    visibility: props.inventory?.visibility ?? "members_only",
    location:
      (props.inventory as { location?: string } | undefined)?.location ?? "",
    image: undefined as string | undefined,
    managedBy:
      (props.inventory?.manager as { id?: string } | undefined)?.id ??
      (undefined as string | undefined),
  },
});

const [name, nameProps] = defineField("name");
const [description, descriptionProps] = defineField("description");
const [image, imageProps] = defineField("image");
const [visibility, visibilityProps] = defineField("visibility");
const [location, locationProps] = defineField("location");
const [managedBy] = defineField("managedBy");

const visibilityOptions: FilterOption[] = [
  {
    value: "members_only",
    label: t("labels.fleets.logistics.visibilities.members_only"),
  },
  {
    value: "officers_only",
    label: t("labels.fleets.logistics.visibilities.officers_only"),
  },
];

const fetchMembers = (params: FilterGroupParams<FilterOption>) => {
  return fetchFleetMembers(props.fleet.slug, {
    q: { usernameCont: params.search || undefined },
  });
};

const formatMembers = (response: { items: FleetMember[] }) => {
  return (response.items || []).map((m) => ({
    label: m.username,
    value: m.userId || "",
  }));
};

const createMutation = useCreateFleetInventory();
const updateMutation = useUpdateFleetInventory();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data = {
    name: values.name,
    description: values.description || undefined,
    visibility: values.visibility as "members_only" | "officers_only",
    location: values.location || undefined,
    image: values.image || undefined,
    managedBy: values.managedBy || undefined,
  };

  const mutation = isEdit.value
    ? updateMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        slug: props.inventory!.slug,
        data,
      })
    : createMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        data,
      });

  await mutation
    .then(() => {
      displaySuccess({
        text: isEdit.value
          ? t("messages.fleets.logistics.inventory.update.success")
          : t("messages.fleets.logistics.inventory.create.success"),
      });
      comlink.emit(
        isEdit.value ? "fleet-inventory-updated" : "fleet-inventory-created",
      );
      comlink.emit("close-modal");
    })
    .catch(() => {
      displayAlert({
        text: isEdit.value
          ? t("messages.fleets.logistics.inventory.update.failure")
          : t("messages.fleets.logistics.inventory.create.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <Modal
    :title="
      isEdit
        ? t('headlines.fleets.logistics.editInventory')
        : t('headlines.fleets.logistics.createInventory')
    "
  >
    <form id="inventory-form" @submit.prevent="onSubmit">
      <FormFileInput
        v-model="image"
        v-bind="imageProps"
        :file="(inventory as any)?.image"
        name="image"
        :label="t('labels.fleets.logistics.image')"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
      />
      <FormInput
        v-model="name"
        v-bind="nameProps"
        name="name"
        :rules="validationSchema.name"
        :label="t('labels.fleets.logistics.inventoryName')"
      />
      <FormTextarea
        v-model="description"
        v-bind="descriptionProps"
        name="description"
        :label="t('labels.fleets.logistics.description')"
      />
      <FormInput
        v-model="location"
        v-bind="locationProps"
        name="location"
        :label="t('labels.fleets.logistics.location')"
      />
      <FilterGroup
        v-model="visibility"
        v-bind="visibilityProps"
        name="visibility"
        :options="visibilityOptions"
        :label="t('labels.fleets.logistics.visibility')"
        :searchable="false"
      />
      <FilterGroup
        v-model="managedBy"
        :query-fn="fetchMembers"
        :query-response-formatter="formatMembers"
        :label="t('labels.fleets.logistics.managedBy')"
        name="managedBy"
        :searchable="true"
        :nullable="true"
      />
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :loading="submitting"
          :size="BtnSizesEnum.LARGE"
          :inline="true"
          @click="onSubmit"
        >
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

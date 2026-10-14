<script lang="ts">
export default {
  name: "VehicleEditModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormTabs from "@/shared/components/base/FormTabs/index.vue";
import FormTab from "@/shared/components/base/FormTabs/Tab/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  firstErrorMessageFrom,
  validationErrorFrom,
} from "@/shared/utils/ApiErrors";
import {
  type Vehicle,
  type VehicleUpdateInput,
  useUpdateVehicle,
} from "@/services/fyApi";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import General from "./General/index.vue";
import Visibility from "./Visibility/index.vue";
import Names from "./Names/index.vue";
import Groups from "./Groups/index.vue";
import ImagePanel from "./Image/index.vue";
import { VehicleEditTabsEnum, type VehicleEditValues } from "./types";

type Props = {
  vehicle: Vehicle;
  wishlist?: boolean;
  tab?: VehicleEditTabsEnum;
};

const props = withDefaults(defineProps<Props>(), {
  wishlist: false,
  tab: VehicleEditTabsEnum.GENERAL,
});

const { t } = useI18n();

const comlink = useComlink();

const { displayAlert, displaySuccess } = useAppNotifications();

const savedValues = (): VehicleEditValues => ({
  flagship: props.vehicle.flagship,
  boughtVia: props.vehicle.boughtVia,
  public: props.vehicle.public,
  nameVisible: props.vehicle.nameVisible,
  saleNotify: props.vehicle.saleNotify,
  logEntriesPublicByDefault: props.vehicle.logEntriesPublicByDefault,
  name: props.vehicle.name,
  serial: props.vehicle.serial,
  alternativeNames: [...props.vehicle.alternativeNames],
  hangarGroupIds: [...props.vehicle.hangarGroupIds],
});

const EDITABLE_FIELDS = Object.keys(
  savedValues(),
) as (keyof VehicleUpdateInput & keyof VehicleEditValues)[];

const { handleSubmit, resetForm, setErrors, meta } = useForm<VehicleEditValues>(
  {
    initialValues: savedValues(),
  },
);

// A pending edit wins over the refresh, or a background refetch of the hangar
// would discard what was typed and not yet saved.
watch(
  () => props.vehicle,
  () => {
    if (meta.value.dirty) return;

    resetForm({ values: savedValues() });
  },
);

// Only what changed is sent: a serial from before the game format must not be
// re-validated because the groups were edited.
const changedFields = (values: VehicleEditValues) => {
  const saved = savedValues();

  const changes = EDITABLE_FIELDS.reduce<VehicleUpdateInput>((data, field) => {
    if (JSON.stringify(values[field]) !== JSON.stringify(saved[field])) {
      return { ...data, [field]: values[field] };
    }

    return data;
  }, {});

  return Object.keys(changes).length ? changes : undefined;
};

const activeTab = ref<string>(props.tab);

// The gallery is fetched by the image tab itself, so it waits until the tab is
// first opened rather than loading with every edit.
const imageTabOpened = ref(props.tab === VehicleEditTabsEnum.IMAGE);

watch(activeTab, (tab) => {
  if (tab === VehicleEditTabsEnum.IMAGE) {
    imageTabOpened.value = true;
  }
});

const imagePanel = ref<InstanceType<typeof ImagePanel> | null>(null);

const { useUpdateMutation, invalidateVehiclePage, invalidateHangarQueries } =
  useVehicleMutations();

const vehicle = computed(() => props.vehicle);

const updateMutation = useUpdateMutation(vehicle);

// Not the hangar's optimistic update for a picture: that merges the request
// into the cached vehicle, and the request carries a signed blob id where the
// vehicle holds a file.
const imageMutation = useUpdateVehicle();

const submitting = computed(
  () => updateMutation.isPending.value || imageMutation.isPending.value,
);

const save = async (data: VehicleUpdateInput, withImage: boolean) => {
  if (!withImage) {
    await updateMutation.mutateAsync({ id: props.vehicle.id, data });
    return;
  }

  const updatedVehicle = await imageMutation.mutateAsync({
    id: props.vehicle.id,
    data,
  });

  await Promise.all([
    invalidateVehiclePage(updatedVehicle),
    invalidateHangarQueries(),
  ]);

  displaySuccess({ text: t("messages.vehicleOverview.image.success") });
};

const onSubmit = handleSubmit(async (values) => {
  const changes = changedFields(values);
  const imageChanges = imagePanel.value?.changes();

  if (!changes && !imageChanges) {
    comlink.emit("close-modal");
    return;
  }

  await save({ ...changes, ...imageChanges }, !!imageChanges)
    .then(() => {
      comlink.emit("close-modal");
    })
    .catch((error) => {
      const { message, formErrors } = validationErrorFrom(error);

      setErrors(formErrors);

      // The field's own reason -- an SVG for the picture, say -- is what tells
      // the owner what would work instead.
      displayAlert({
        text: [message, firstErrorMessageFrom(error)]
          .filter(Boolean)
          .join(": "),
      });
    });
});

const vehicleName = computed(
  () => props.vehicle.name || props.vehicle.model?.name,
);
</script>

<template>
  <Modal v-if="vehicle">
    <template #title>
      <span>{{ t("headlines.editMyVehicle", { vehicle: vehicleName }) }}</span>
      <small v-if="vehicle.serial" class="text-muted">
        {{ vehicle.serial }}
      </small>
      <br />

      <small class="text-muted">
        <!-- eslint-disable-next-line vue/no-v-html -->
        <span v-html="vehicle.model?.manufacturer?.name" />
        {{ vehicle.model?.name }}
      </small>
    </template>

    <form
      :id="`vehicle-edit-${vehicle.id}`"
      data-test="vehicle-edit-form"
      @submit.prevent="onSubmit"
    >
      <FormTabs
        v-model:active-tab="activeTab"
        :sync-url="false"
        horizontal
        active-label-only
      >
        <FormTab
          :id="VehicleEditTabsEnum.GENERAL"
          :label="t('labels.vehicleEdit.tabs.general')"
          icon="fa-duotone fa-sliders"
          :fields="['boughtVia', 'flagship']"
        >
          <General :vehicle="vehicle" :wishlist="wishlist" />
        </FormTab>
        <FormTab
          :id="VehicleEditTabsEnum.VISIBILITY"
          :label="t('labels.vehicleEdit.tabs.visibility')"
          icon="fa-duotone fa-eye"
          :fields="[
            'public',
            'nameVisible',
            'saleNotify',
            'logEntriesPublicByDefault',
          ]"
        >
          <Visibility :wishlist="wishlist" />
        </FormTab>
        <FormTab
          :id="VehicleEditTabsEnum.NAMES"
          :label="t('labels.vehicleEdit.tabs.names')"
          icon="fa-duotone fa-signature"
          :fields="['name', 'serial', 'alternativeNames']"
        >
          <Names :vehicle="vehicle" />
        </FormTab>
        <FormTab
          :id="VehicleEditTabsEnum.GROUPS"
          :label="t('labels.vehicleEdit.tabs.groups')"
          icon="fa-duotone fa-object-group"
          :fields="['hangarGroupIds']"
          :hidden="wishlist"
        >
          <Groups v-if="!wishlist" />
        </FormTab>
        <FormTab
          :id="VehicleEditTabsEnum.IMAGE"
          :label="t('labels.vehicleEdit.tabs.picture')"
          icon="fa-duotone fa-camera"
          :fields="['image']"
        >
          <ImagePanel
            v-if="imageTabOpened"
            ref="imagePanel"
            :vehicle="vehicle"
          />
        </FormTab>
      </FormTabs>
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        :form="`vehicle-edit-${vehicle.id}`"
        :loading="submitting"
        data-test="vehicle-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>

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
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  firstErrorMessageFrom,
  validationErrorFrom,
} from "@/shared/utils/ApiErrors";
import {
  type Vehicle,
  type VehicleUpdateInput,
  getVehiclePaintsQueryKey,
  useUpdateVehicle,
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import General from "./General/index.vue";
import Visibility from "./Visibility/index.vue";
import Names from "./Names/index.vue";
import Groups from "./Groups/index.vue";
import ImagePanel from "./Image/index.vue";
import Modules from "./Modules/index.vue";
import Upgrades from "./Upgrades/index.vue";
import Paint from "./Paint/index.vue";
import { VehicleEditTabsEnum, type VehicleEditValues } from "./types";

type Props = {
  vehicle: Vehicle;
  wishlist?: boolean;
  tab?: VehicleEditTabsEnum;
  // A paint picked elsewhere, added to the owned ones here to be saved.
  paintId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  wishlist: false,
  tab: VehicleEditTabsEnum.GENERAL,
  paintId: undefined,
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
  modelModuleIds: [...props.vehicle.modelModuleIds],
  modelUpgradeIds: [...props.vehicle.modelUpgradeIds],
  modelPaintIds: [...props.vehicle.modelPaintIds],
});

const EDITABLE_FIELDS = Object.keys(
  savedValues(),
) as (keyof VehicleUpdateInput & keyof VehicleEditValues)[];

const initialValues = savedValues();

const { handleSubmit, resetForm, setErrors, meta, setFieldValue, values } =
  useForm<VehicleEditValues>({
    initialValues,
  });

// Set as a pending choice rather than an initial value, so it saves like a pick
// and survives a background refetch of the hangar.
if (props.paintId && !props.vehicle.modelPaintIds.includes(props.paintId)) {
  setFieldValue("modelPaintIds", [
    ...props.vehicle.modelPaintIds,
    props.paintId,
  ]);
}

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

// A wishlist ship is only named and watched for sales; how it was bought, its
// groups and its picture belong to a ship in the hangar.
const WISHLIST_TABS = [
  VehicleEditTabsEnum.NAMES,
  VehicleEditTabsEnum.VISIBILITY,
];

const tabVisible = (tab: VehicleEditTabsEnum) =>
  !props.wishlist || WISHLIST_TABS.includes(tab);

// What a ship carries is the owner's record of it; a loaner carries what it was
// lent with.
const equipmentVisible = computed(
  () => !props.wishlist && !props.vehicle.loaner,
);

const activeTab = ref<string>(
  tabVisible(props.tab) ? props.tab : VehicleEditTabsEnum.NAMES,
);

// The gallery is fetched by the image tab itself, so it waits until the tab is
// first opened rather than loading with every edit.
const imageTabOpened = ref(props.tab === VehicleEditTabsEnum.IMAGE);

// Likewise the paint tab, whose pledge suggestion fills the owned paints: it
// must only do that where the owner can see it, or any save would take it along.
const paintTabOpened = ref(props.tab === VehicleEditTabsEnum.PAINT);

watch(activeTab, (tab) => {
  if (tab === VehicleEditTabsEnum.IMAGE) {
    imageTabOpened.value = true;
  }
  if (tab === VehicleEditTabsEnum.PAINT) {
    paintTabOpened.value = true;
  }
});

const imagePanel = ref<InstanceType<typeof ImagePanel> | null>(null);

// The paint tab fills in the pledged paints as a suggestion. Left as it was
// suggested, closing loses nothing the user did, so it does not ask.
const suggestedPaintIds = ref<string[]>();

const suggestedValues = (): VehicleEditValues => ({
  ...savedValues(),
  ...(suggestedPaintIds.value
    ? { modelPaintIds: suggestedPaintIds.value }
    : {}),
});

const editedFromSaved = useFormDirty(values, savedValues);

const editedFromSuggestion = useFormDirty(values, suggestedValues);

const formDirty = computed(
  () => editedFromSaved.value && editedFromSuggestion.value,
);

// The picture is picked outside the form, so its tab answers for itself.
useModalDirty(() => formDirty.value || !!imagePanel.value?.changes());

const { useUpdateMutation, invalidateVehiclePage, invalidateHangarQueries } =
  useVehicleMutations();

const vehicle = computed(() => props.vehicle);

const queryClient = useQueryClient();

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
    comlink.emit("close-modal", true);
    return;
  }

  await save({ ...changes, ...imageChanges }, !!imageChanges)
    .then(async () => {
      if (
        (changes && "modelPaintIds" in changes) ||
        (imageChanges && "pictureId" in imageChanges)
      ) {
        await queryClient.invalidateQueries({
          queryKey: getVehiclePaintsQueryKey(props.vehicle.id),
        });
      }

      comlink.emit("close-modal", true);
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
  <Modal v-if="vehicle" tabbed>
    <template #eyebrow>
      <!-- eslint-disable-next-line vue/no-v-html -->
      <span v-html="vehicle.model?.manufacturer?.name" />
      · {{ vehicle.model?.name }}
      <template v-if="vehicle.serial"> · {{ vehicle.serial }}</template>
    </template>
    <template #title>
      {{ t("headlines.editMyVehicle", { vehicle: vehicleName }) }}
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
          :hidden="!tabVisible(VehicleEditTabsEnum.GENERAL)"
        >
          <General v-if="!wishlist" :vehicle="vehicle" />
        </FormTab>
        <FormTab
          :id="VehicleEditTabsEnum.VISIBILITY"
          :label="
            wishlist
              ? t('labels.vehicleEdit.tabs.notifications')
              : t('labels.vehicleEdit.tabs.visibility')
          "
          :icon="wishlist ? 'fa-duotone fa-bell' : 'fa-duotone fa-eye'"
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
          :hidden="!tabVisible(VehicleEditTabsEnum.GROUPS)"
        >
          <Groups v-if="!wishlist" />
        </FormTab>
        <FormTab
          :id="VehicleEditTabsEnum.IMAGE"
          :label="t('labels.vehicleEdit.tabs.picture')"
          icon="fa-duotone fa-camera"
          :fields="['image']"
          :hidden="!tabVisible(VehicleEditTabsEnum.IMAGE)"
        >
          <ImagePanel
            v-if="imageTabOpened && !wishlist"
            ref="imagePanel"
            :vehicle="vehicle"
          />
        </FormTab>
        <FormTab
          :id="VehicleEditTabsEnum.MODULES"
          :label="t('labels.vehicleLoadout.tabs.modules')"
          icon="fa-duotone fa-puzzle"
          :fields="['modelModuleIds']"
          :hidden="!equipmentVisible || !vehicle.model.hasModules"
        >
          <Modules
            v-if="equipmentVisible && vehicle.model.hasModules"
            :vehicle="vehicle"
          />
        </FormTab>
        <FormTab
          :id="VehicleEditTabsEnum.UPGRADES"
          :label="t('labels.vehicleLoadout.tabs.upgrades')"
          icon="fa-duotone fa-wrench"
          :fields="['modelUpgradeIds']"
          :hidden="!equipmentVisible || !vehicle.model.hasUpgrades"
        >
          <Upgrades
            v-if="equipmentVisible && vehicle.model.hasUpgrades"
            :vehicle="vehicle"
          />
        </FormTab>
        <FormTab
          :id="VehicleEditTabsEnum.PAINT"
          :label="t('labels.vehicleLoadout.tabs.paints')"
          icon="fa-duotone fa-paint-roller"
          :fields="['modelPaintIds']"
          :hidden="!equipmentVisible || !vehicle.model.hasPaints"
        >
          <Paint
            v-if="paintTabOpened && equipmentVisible && vehicle.model.hasPaints"
            :vehicle="vehicle"
            @suggest="suggestedPaintIds = $event"
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

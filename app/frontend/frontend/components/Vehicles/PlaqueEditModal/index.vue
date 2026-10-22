<script lang="ts">
export default {
  name: "VehiclePlaqueEditModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import {
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { plaqueMakerFor } from "@/frontend/components/Vehicles/Plaque/makers";
import {
  FREE_PLAQUE_STYLE,
  defaultPlaqueStyle,
} from "@/frontend/components/Vehicles/Plaque/styles";
import VehiclePlaque from "@/frontend/components/Vehicles/Plaque/index.vue";
import PlaqueFields from "@/frontend/components/Vehicles/PlaqueFields/index.vue";
import PlaqueStylePicker from "@/frontend/components/Vehicles/PlaqueStylePicker/index.vue";
import PlaqueCapture from "@/frontend/components/Vehicles/PlaqueCapture/index.vue";
import { ownerCaptain } from "@/frontend/components/Vehicles/Plaque/captain";
import { usePlaqueImageUpload } from "@/frontend/composables/usePlaqueImageUpload";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { type Vehicle } from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();

const vehicle = computed(() => props.vehicle);

const { currentUser } = storeToRefs(useSessionStore());

const maker = computed(() => plaqueMakerFor(props.vehicle));

const isSupporter = computed(() => !!currentUser?.value?.supporter);

const defaultStyle = computed(() =>
  defaultPlaqueStyle(isSupporter.value, maker.value),
);

// A supporter style outlasts the support, but only until the plaque is edited:
// the server switches it to brass on the next save, so the form does too.
const keptStyle =
  !!currentUser?.value &&
  !isSupporter.value &&
  !!props.vehicle.dedication &&
  !!props.vehicle.plaqueStyle &&
  props.vehicle.plaqueStyle !== FREE_PLAQUE_STYLE
    ? props.vehicle.plaqueStyle
    : undefined;

const initialValues = {
  dedication: props.vehicle.dedication ?? "",
  dedicationVerse: props.vehicle.dedicationVerse ?? "",
  launchedOn: props.vehicle.launchedOn ?? null,
  launchPort: props.vehicle.launchPort ?? "",
  launchPortLocationId: props.vehicle.launchPortLocation?.id ?? null,
  affiliation: props.vehicle.affiliation ?? "",
  plaqueCaptain: props.vehicle.plaqueCaptain ?? "",
  operationsGroup: props.vehicle.operationsGroup ?? null,
  plaqueLocale: props.vehicle.plaqueLocale ?? null,
  plaqueStyle: keptStyle
    ? FREE_PLAQUE_STYLE
    : props.vehicle.dedication
      ? (props.vehicle.plaqueStyle ?? defaultStyle.value)
      : defaultStyle.value,
};

const { defineField, handleSubmit, values } = useForm({
  // The style page swaps the fields out; without this, coming back from it
  // finds every line typed so far gone.
  keepValuesOnUnmount: true,
  initialValues,
});

useModalDirty(useFormDirty(values, initialValues));

const [dedication] = defineField("dedication");
const [dedicationVerse] = defineField("dedicationVerse");
const [launchedOn] = defineField("launchedOn");
const [launchPort] = defineField("launchPort");
const [launchPortLocationId] = defineField("launchPortLocationId");
const [affiliation] = defineField("affiliation");
const [plaqueCaptain] = defineField("plaqueCaptain");
const [operationsGroup] = defineField("operationsGroup");
const [plaqueStyle] = defineField("plaqueStyle");
const [plaqueLocale] = defineField("plaqueLocale");

// The styles are a page of their own, like the sync modal's settings: picking
// one there sets the form, and the back button returns to it.
const stylesOpen = ref(false);

// The plaque as it will read once saved, so a style is picked by looking at it.
const preview = computed<Vehicle>(() => ({
  ...props.vehicle,
  dedication: dedication.value || null,
  dedicationVerse: dedicationVerse.value || null,
  launchedOn: launchedOn.value || null,
  launchPort: launchPort.value || null,
  affiliation: affiliation.value || null,
  plaqueCaptain: plaqueCaptain.value || null,
  operationsGroup: operationsGroup.value || null,
  plaqueStyle: plaqueStyle.value,
  plaqueLocale: plaqueLocale.value,
}));

// The fleets the ship is listed in, offered as the organization it serves.
const fleetNames = computed(() =>
  (props.vehicle.fleets ?? []).map((fleet) => fleet.name),
);

const { useUpdateMutation } = useVehicleMutations();
const updateMutation = useUpdateMutation(vehicle);

// The payload carries the style the plaque is drawn in, not the stored choice,
// so on an existing plaque it is only sent once picked: otherwise saving any
// line would pin the default as a choice of its own. A new plaque always sends
// it, as the style the form starts on is not the server's default.
const initialPlaqueStyle = props.vehicle.dedication
  ? (keptStyle ?? plaqueStyle.value)
  : undefined;

const capture = ref<InstanceType<typeof PlaqueCapture>>();

// The owner as the public sees them, in the previews as in the picture, so
// the plaque on screen is the one a shared link shows.
const captain = computed(() => ownerCaptain(currentUser?.value));

const { capturing, upload } = usePlaqueImageUpload((signedId) =>
  updateMutation.mutateAsync({
    id: props.vehicle.id,
    data: { plaqueImage: signedId },
  }),
);

// The dedication is required to save a plaque, so taking one down is its own
// action: every line cleared, and the server drops the picture with it.
const removePlaque = async () => {
  await updateMutation
    .mutateAsync({
      id: props.vehicle.id,
      data: {
        dedication: null,
        dedicationVerse: null,
        launchedOn: null,
        launchPort: null,
        launchPortLocationId: null,
        affiliation: null,
        plaqueCaptain: null,
        operationsGroup: null,
        plaqueLocale: null,
      },
    })
    .then(() => comlink.emit("close-modal", true))
    .catch(() => {
      displayAlert({ text: t("messages.vehiclePlaque.failure") });
    });
};

const onSubmit = handleSubmit(async (values) => {
  await updateMutation
    .mutateAsync({
      id: props.vehicle.id,
      // Null rather than left out: a cleared field clears the line.
      data: {
        dedication: values.dedication || null,
        dedicationVerse: values.dedicationVerse || null,
        launchedOn: values.launchedOn || null,
        launchPort: values.launchPort || null,
        launchPortLocationId: values.launchPortLocationId ?? null,
        affiliation: values.affiliation || null,
        plaqueCaptain: values.plaqueCaptain || null,
        operationsGroup: values.operationsGroup || null,
        plaqueLocale: values.plaqueLocale,
        ...(values.plaqueStyle !== initialPlaqueStyle
          ? { plaqueStyle: values.plaqueStyle || null }
          : {}),
      },
    })
    .then(async () => {
      if (values.dedication) {
        await upload(capture.value?.plaque());
      }
      comlink.emit("close-modal", true);
    })
    .catch(() => {
      displayAlert({ text: t("messages.vehiclePlaque.failure") });
    });
});
</script>

<template>
  <Modal :title="t('headlines.vehiclePlaque.title')">
    <form id="vehicle-plaque-form" @submit.prevent="onSubmit">
      <transition name="fade" mode="out-in">
        <PlaqueStylePicker
          v-if="stylesOpen"
          key="styles"
          v-model="plaqueStyle"
          :vehicle="preview"
          :captain="captain"
          :is-supporter="isSupporter"
          @support="comlink.emit('close-modal')"
        />
        <div v-else key="details">
          <Alert
            v-if="keptStyle"
            :variant="AlertVariantsEnum.WARNING"
            data-test="vehicle-plaque-kept-style"
          >
            {{
              t("texts.vehiclePlaque.keptStyle", {
                style: t(`labels.vehiclePlaque.styles.${keptStyle}`),
                default: t(`labels.vehiclePlaque.styles.${FREE_PLAQUE_STYLE}`),
              })
            }}
          </Alert>
          <VehiclePlaque
            :vehicle="preview"
            :captain="captain"
            class="plaque-edit__preview"
            data-test="vehicle-plaque-preview"
          />
          <PlaqueFields
            v-model:dedication="dedication"
            v-model:dedication-verse="dedicationVerse"
            v-model:launched-on="launchedOn"
            v-model:launch-port="launchPort"
            v-model:launch-port-location-id="launchPortLocationId"
            v-model:affiliation="affiliation"
            v-model:plaque-captain="plaqueCaptain"
            v-model:operations-group="operationsGroup"
            v-model:plaque-locale="plaqueLocale"
            :linked-launch-port="vehicle.launchPortLocation"
            :captain-placeholder="captain"
            :fleet-names="fleetNames"
          />
          <p class="text-muted">{{ t("texts.vehiclePlaque.visibility") }}</p>
        </div>
      </transition>
    </form>

    <PlaqueCapture ref="capture" :vehicle="preview" :captain="captain" />

    <template #footer-start>
      <Btn
        v-if="stylesOpen"
        :variant="BtnVariantsEnum.BARE"
        data-test="vehicle-plaque-styles-back"
        @click="stylesOpen = false"
      >
        <i class="fa-light fa-chevron-left" />
        {{ t("actions.back") }}
      </Btn>
      <template v-else>
        <Btn
          :variant="BtnVariantsEnum.BARE"
          data-test="vehicle-plaque-styles-open"
          @click="stylesOpen = true"
        >
          <i class="fa-light fa-palette" />
          {{ t("labels.vehiclePlaque.style") }}
        </Btn>
        <Btn
          v-if="vehicle.dedication"
          :variant="BtnVariantsEnum.BARE"
          :tone="BtnTonesEnum.DANGER"
          :confirm="t('messages.vehiclePlaque.removeConfirm')"
          :disabled="updateMutation.isPending.value || capturing"
          data-test="vehicle-plaque-remove"
          @click="removePlaque"
        >
          {{ t("actions.vehiclePlaque.remove") }}
        </Btn>
      </template>
    </template>
    <template v-if="!stylesOpen" #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="vehicle-plaque-form"
        :loading="updateMutation.isPending.value || capturing"
        data-test="vehicle-plaque-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
// A glance at the plaque, not the plaque itself: small and centred above the
// fields. It scales as a whole, so a narrower frame is a smaller plaque.
.plaque-edit__preview {
  max-width: 480px;
  margin: 0 auto 20px;
}
</style>

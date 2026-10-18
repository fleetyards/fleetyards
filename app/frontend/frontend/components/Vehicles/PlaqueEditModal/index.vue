<script lang="ts">
export default {
  name: "VehiclePlaqueEditModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormDatePicker from "@/shared/components/base/FormDatePicker/index.vue";
import LocationInput from "@/shared/components/LocationInput/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { OPERATIONS_GROUPS } from "@/frontend/components/Vehicles/Plaque/operationsGroups";
import { plaqueMakerFor } from "@/frontend/components/Vehicles/Plaque/makers";
import VehiclePlaque from "@/frontend/components/Vehicles/Plaque/index.vue";
import { IN_UNIVERSE_YEAR_OFFSET } from "@/frontend/components/Vehicles/Plaque/launchDate";
import { plaqueSocialImage } from "@/frontend/components/Vehicles/Plaque/download";
import { ownerCaptain } from "@/frontend/components/Vehicles/Plaque/captain";
import { useDirectUpload } from "@/shared/composables/useDirectUpload";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import {
  NullableVehiclePlaqueStyleEnum,
  type Vehicle,
  type VehiclePlaqueStyleEnum,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const DEDICATION_LIMIT = 150;
const DEDICATION_VERSE_LIMIT = 500;
const LINE_LIMIT = 100;
const CAPTAIN_LIMIT = 50;

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();

const vehicle = computed(() => props.vehicle);

const { currentUser } = storeToRefs(useSessionStore());

const maker = computed(() => plaqueMakerFor(props.vehicle));

const isSupporter = computed(() => !!currentUser?.value?.supporter);

// Brass is free; every other style is a supporter perk. A supporter whose ship
// has a maker style of its own starts on it: it is the plaque made for that ship.
const FREE_STYLE: VehiclePlaqueStyleEnum = "brass";

const defaultStyle = computed<VehiclePlaqueStyleEnum>(() =>
  isSupporter.value && maker.value ? "manufacturer" : FREE_STYLE,
);

// A supporter style outlasts the support, but only until the plaque is edited:
// the server switches it to brass on the next save, so the form does too.
const keptStyle =
  !!currentUser?.value &&
  !isSupporter.value &&
  !!props.vehicle.dedication &&
  !!props.vehicle.plaqueStyle &&
  props.vehicle.plaqueStyle !== FREE_STYLE
    ? props.vehicle.plaqueStyle
    : undefined;

const validationSchema = {
  // Without one there is no plaque, and the other lines would save to nothing.
  dedication: `required|max:${DEDICATION_LIMIT}`,
  dedicationVerse: `max:${DEDICATION_VERSE_LIMIT}`,
  launchPort: `max:${LINE_LIMIT}`,
  affiliation: `max:${LINE_LIMIT}`,
  plaqueCaptain: `max:${CAPTAIN_LIMIT}`,
};

const initialValues = {
  dedication: props.vehicle.dedication ?? "",
  dedicationVerse: props.vehicle.dedicationVerse ?? "",
  launchedOn: props.vehicle.launchedOn ?? null,
  launchPort: props.vehicle.launchPort ?? "",
  launchPortLocationId: props.vehicle.launchPortLocation?.id ?? null,
  affiliation: props.vehicle.affiliation ?? "",
  plaqueCaptain: props.vehicle.plaqueCaptain ?? "",
  operationsGroup: props.vehicle.operationsGroup ?? null,
  plaqueStyle: keptStyle
    ? FREE_STYLE
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

// Every style is shown, the ones a supporter unlocks greyed out for anyone else,
// so the perk is visible where it would be used.
const plaqueStyleOptions = computed(() =>
  Object.values(NullableVehiclePlaqueStyleEnum)
    .filter((style): style is VehiclePlaqueStyleEnum => !!style)
    .filter((style) => style !== "manufacturer" || !!maker.value)
    .map((style) => ({
      value: style,
      label: t(`labels.vehiclePlaque.styles.${style}`),
      locked: !isSupporter.value && style !== FREE_STYLE,
    })),
);

// The plaque as it will read once saved, so a style is picked by looking at it.
const previewFor = (style: VehiclePlaqueStyleEnum): Vehicle => ({
  ...preview.value,
  id: `${props.vehicle.id}-${style}`,
  plaqueStyle: style,
});

// The styles are a page of their own, like the sync modal's settings: picking
// one there sets the form, and the back button returns to it.
const stylesOpen = ref(false);

const freeStyleOptions = computed(() =>
  plaqueStyleOptions.value.filter((option) => !option.locked),
);

const lockedStyleOptions = computed(() =>
  plaqueStyleOptions.value.filter((option) => option.locked),
);

// The perk styles show in full; the call to support covers them only on hover,
// keyboard focus, or -- where nothing hovers -- a tap on one of them.
const upsellShown = ref(false);

const pickStyle = (option: {
  value: VehiclePlaqueStyleEnum;
  locked: boolean;
}) => {
  if (option.locked) {
    upsellShown.value = true;
    return;
  }

  plaqueStyle.value = option.value;
};

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
}));

// Grouped by side of the law, lawful first, as the select keeps this order.
const operationsGroupOptions = computed(() =>
  Object.entries(OPERATIONS_GROUPS).map(([value, group]) => ({
    value,
    label: `${group.name} · ${t(`labels.fleet.alignments.${group.alignment}`)}`,
  })),
);

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

const { uploadFile } = useDirectUpload();

// An off-screen copy at a fixed width, so the picture is the same whatever the
// screen the plaque was saved on.
const capture = ref<HTMLElement>();
const capturing = ref(false);

// Drawn as the public sees it, since anyone the link reaches gets the picture:
// a name and serial the owner keeps to themselves stay off it.
const captureVehicle = computed<Vehicle>(() => ({
  ...preview.value,
  id: `${props.vehicle.id}-capture`,
  name: props.vehicle.nameVisible ? preview.value.name : undefined,
  serial: props.vehicle.nameVisible ? preview.value.serial : undefined,
}));

// The owner as the public sees them, in the previews as in the picture, so
// the plaque on screen is the one a shared link shows.
const captain = computed(() => ownerCaptain(currentUser?.value));

// The plaque as a picture, for the preview of a shared link. Rendered here
// because only the browser can draw it; a failure leaves the plaque saved and
// only its preview behind.
const uploadPlaqueImage = async () => {
  const element = capture.value?.querySelector<HTMLElement>(".vehicle-plaque");
  if (!element) {
    return;
  }

  capturing.value = true;

  try {
    const file = await plaqueSocialImage(element);
    const blob = await uploadFile(file, { progressHandler: () => undefined });

    await updateMutation.mutateAsync({
      id: props.vehicle.id,
      data: { plaqueImage: blob.signed_id },
    });
  } catch {
    // The link preview falls back to the hangar's own until the next save.
  } finally {
    capturing.value = false;
  }
};

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
        ...(values.plaqueStyle !== initialPlaqueStyle
          ? { plaqueStyle: values.plaqueStyle || null }
          : {}),
      },
    })
    .then(async () => {
      if (values.dedication) {
        await uploadPlaqueImage();
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
        <div v-if="stylesOpen" key="styles" data-test="vehicle-plaque-styles">
          <div class="plaque-edit__styles" data-test="vehicle-plaque-style">
            <button
              v-for="option in freeStyleOptions"
              :key="option.value"
              type="button"
              class="plaque-edit__style"
              :class="{
                'plaque-edit__style--active': plaqueStyle === option.value,
                'plaque-edit__style--locked': option.locked,
              }"
              :aria-pressed="plaqueStyle === option.value"
              :aria-disabled="option.locked"
              :data-test="`vehicle-plaque-style-${option.value}`"
              @click="pickStyle(option)"
            >
              <VehiclePlaque
                :vehicle="previewFor(option.value)"
                :captain="captain"
              />
              <span class="plaque-edit__style-label">
                <i v-if="option.locked" class="fa-light fa-lock" />
                {{ option.label }}
              </span>
            </button>
          </div>
          <!-- The styles a supporter unlocks, under one call to support: the
               perk is shown where it would be used, not described elsewhere. -->
          <div
            v-if="lockedStyleOptions.length"
            class="plaque-edit__locked"
            :class="{ 'plaque-edit__locked--open': upsellShown }"
            @mouseleave="upsellShown = false"
          >
            <div class="plaque-edit__styles">
              <button
                v-for="option in lockedStyleOptions"
                :key="option.value"
                type="button"
                class="plaque-edit__style"
                :class="{
                  'plaque-edit__style--active': plaqueStyle === option.value,
                  'plaque-edit__style--locked': option.locked,
                }"
                :aria-pressed="plaqueStyle === option.value"
                :aria-disabled="option.locked"
                :data-test="`vehicle-plaque-style-${option.value}`"
                @click="pickStyle(option)"
              >
                <VehiclePlaque
                  :vehicle="previewFor(option.value)"
                  :captain="captain"
                />
                <span class="plaque-edit__style-label">
                  <i v-if="option.locked" class="fa-light fa-lock" />
                  {{ option.label }}
                </span>
              </button>
            </div>
            <div class="plaque-edit__upsell" data-test="vehicle-plaque-upsell">
              <div class="plaque-edit__upsell-box">
                <i class="fa-light fa-lock" />
                <p>{{ t("texts.vehiclePlaque.supporter") }}</p>
                <Btn
                  :to="{ name: 'support' }"
                  data-test="vehicle-plaque-support"
                  @click="comlink.emit('close-modal')"
                >
                  {{ t("actions.supportUs") }}
                </Btn>
              </div>
            </div>
          </div>
        </div>
        <div v-else key="details">
          <Alert
            v-if="keptStyle"
            :variant="AlertVariantsEnum.WARNING"
            data-test="vehicle-plaque-kept-style"
          >
            {{
              t("texts.vehiclePlaque.keptStyle", {
                style: t(`labels.vehiclePlaque.styles.${keptStyle}`),
                default: t(`labels.vehiclePlaque.styles.${FREE_STYLE}`),
              })
            }}
          </Alert>
          <VehiclePlaque
            :vehicle="preview"
            :captain="captain"
            class="plaque-edit__preview"
            data-test="vehicle-plaque-preview"
          />
          <div class="plaque-edit__fields">
            <div>
              <FormTextarea
                v-model="dedication"
                name="dedication"
                :label="t('labels.vehiclePlaque.dedication')"
                :rules="validationSchema.dedication"
                :maxlength="DEDICATION_LIMIT"
                data-test="vehicle-plaque-dedication-input"
              />
              <FormTextarea
                v-model="dedicationVerse"
                name="dedicationVerse"
                :label="t('labels.vehiclePlaque.dedicationVerse')"
                :info="t('labels.vehiclePlaque.dedicationVerseInfo')"
                :rules="validationSchema.dedicationVerse"
                :maxlength="DEDICATION_VERSE_LIMIT"
                data-test="vehicle-plaque-dedication-verse-input"
              />
              <FormDatePicker
                v-model="launchedOn"
                name="launchedOn"
                :label="t('labels.vehiclePlaque.launchedOn')"
                :year-offset="IN_UNIVERSE_YEAR_OFFSET"
                clearable
              />
            </div>
            <div>
              <LocationInput
                v-model="launchPort"
                v-model:location-id="launchPortLocationId"
                :linked="vehicle.launchPortLocation"
                name="launchPort"
                :label="t('labels.vehiclePlaque.launchPort')"
                :rules="validationSchema.launchPort"
              />
              <FormInput
                v-model="plaqueCaptain"
                name="plaqueCaptain"
                :label="t('labels.vehiclePlaque.captain')"
                :info="t('labels.vehiclePlaque.captainInfo')"
                :placeholder="captain"
                :rules="validationSchema.plaqueCaptain"
                data-test="vehicle-plaque-captain-input"
              />
              <FormInput
                v-model="affiliation"
                name="affiliation"
                :label="t('labels.vehiclePlaque.affiliation')"
                :rules="validationSchema.affiliation"
              />
              <div v-if="fleetNames.length" class="plaque-edit__fleets">
                <span class="text-muted">{{
                  t("texts.vehiclePlaque.fromFleet")
                }}</span>
                <Btn
                  v-for="fleetName in fleetNames"
                  :key="fleetName"
                  :size="BtnSizesEnum.XS"
                  data-test="vehicle-plaque-fleet"
                  @click="affiliation = fleetName"
                >
                  {{ fleetName }}
                </Btn>
              </div>
              <BaseSelect
                v-model="operationsGroup"
                :options="operationsGroupOptions"
                :label="t('labels.vehiclePlaque.operationsGroup')"
                name="operationsGroup"
                :searchable="false"
                unsorted
                nullable
              />
            </div>
          </div>
          <p class="text-muted">{{ t("texts.vehiclePlaque.visibility") }}</p>
        </div>
      </transition>
    </form>

    <div ref="capture" class="plaque-edit__capture" aria-hidden="true">
      <VehiclePlaque :vehicle="captureVehicle" :captain="captain" />
    </div>

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
.plaque-edit__styles {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 14px;
}

.plaque-edit__style {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 6px;
  border: 2px solid transparent;
  border-radius: 10px;
  background: none;
  color: inherit;
  text-align: left;
  cursor: pointer;
  transition: border-color 150ms ease;

  &:hover,
  &:focus-visible {
    border-color: var(--color-edge, rgb(122 130 136 / 0.5));
  }

  &--active,
  &--active:hover {
    border-color: var(--color-primary, #428bca);
  }

  &--locked:hover,
  &--locked:focus-visible {
    border-color: transparent;
  }
}

.plaque-edit__style-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.85rem;
}

.plaque-edit__capture {
  position: fixed;
  top: 0;
  left: -10000px;
  width: 800px;
  pointer-events: none;
}

// Two columns of fields under the full-width preview; one on a narrow screen.
.plaque-edit__fields {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0 24px;

  @media (max-width: $tablet-breakpoint) {
    grid-template-columns: minmax(0, 1fr);
  }
}

.plaque-edit__locked {
  position: relative;
  margin-top: 14px;
}

.plaque-edit__upsell {
  position: absolute;
  inset: 0;
  z-index: 2;
  opacity: 0;
  pointer-events: none;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 48px;
  border-radius: 10px;
  background: rgb(0 0 0 / 0.45);
  backdrop-filter: blur(0);
  // Out a touch quicker than in, so leaving never feels sticky.
  transition:
    opacity 160ms ease-in,
    backdrop-filter 160ms ease-in;
}

.plaque-edit__locked:hover .plaque-edit__upsell,
.plaque-edit__locked:focus-within .plaque-edit__upsell,
.plaque-edit__locked--open .plaque-edit__upsell {
  opacity: 1;
  pointer-events: auto;
  transition:
    opacity 220ms ease-out,
    backdrop-filter 260ms ease-out;

  .plaque-edit__upsell-box {
    opacity: 1;
    transform: none;
    transition:
      opacity 240ms ease-out 60ms,
      transform 320ms cubic-bezier(0.2, 0.9, 0.3, 1.2) 60ms;
  }
}

// The blur and the rise only where motion is welcome; otherwise it just fades.
@media (prefers-reduced-motion: no-preference) {
  .plaque-edit__locked:hover .plaque-edit__upsell,
  .plaque-edit__locked:focus-within .plaque-edit__upsell,
  .plaque-edit__locked--open .plaque-edit__upsell {
    backdrop-filter: blur(3px);
  }

  // Rises and settles in just behind the backdrop.
  .plaque-edit__upsell-box {
    transform: translateY(10px) scale(0.96);
  }
}

// Sticks to the top of the dialog while the styles scroll beneath it.
.plaque-edit__upsell-box {
  position: sticky;
  top: 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  max-width: 380px;
  padding: 20px 24px;
  border: 2px solid var(--color-edge, rgb(122 130 136 / 0.5));
  border-radius: var(--radius-surface-slim, 12px);
  background: var(--color-surface, rgb(39 43 48 / 0.9));
  text-align: center;
  opacity: 0;
  transition:
    opacity 140ms ease-in,
    transform 160ms ease-in;

  i {
    font-size: 1.6rem;
    color: var(--color-primary, #428bca);
  }

  p {
    margin: 0;
  }
}

// A glance at the plaque, not the plaque itself: small and centred above the
// fields. It scales as a whole, so a narrower frame is a smaller plaque.
.plaque-edit__preview {
  max-width: 480px;
  margin: 0 auto 20px;
}

.plaque-edit__fleets {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  margin: -8px 0 16px;
}
</style>

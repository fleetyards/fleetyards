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
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { OPERATIONS_GROUPS } from "@/frontend/components/Vehicles/Plaque/operationsGroups";
import { plaqueMakerFor } from "@/frontend/components/Vehicles/Plaque/makers";
import VehiclePlaque from "@/frontend/components/Vehicles/Plaque/index.vue";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
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

const DEDICATION_LIMIT = 280;
const LINE_LIMIT = 100;

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

const validationSchema = {
  dedication: `max:${DEDICATION_LIMIT}`,
  launchPort: `max:${LINE_LIMIT}`,
  affiliation: `max:${LINE_LIMIT}`,
};

const { defineField, handleSubmit } = useForm({
  initialValues: {
    dedication: props.vehicle.dedication ?? "",
    launchedOn: props.vehicle.launchedOn ?? null,
    launchPort: props.vehicle.launchPort ?? "",
    launchPortLocationId: props.vehicle.launchPortLocation?.id ?? null,
    affiliation: props.vehicle.affiliation ?? "",
    operationsGroup: props.vehicle.operationsGroup ?? null,
    plaqueStyle: props.vehicle.dedication
      ? (props.vehicle.plaqueStyle ?? defaultStyle.value)
      : defaultStyle.value,
  },
});

const [dedication] = defineField("dedication");
const [launchedOn] = defineField("launchedOn");
const [launchPort] = defineField("launchPort");
const [launchPortLocationId] = defineField("launchPortLocationId");
const [affiliation] = defineField("affiliation");
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

const pickStyle = (option: {
  value: VehiclePlaqueStyleEnum;
  locked: boolean;
}) => {
  if (!option.locked) {
    plaqueStyle.value = option.value;
  }
};

const preview = computed<Vehicle>(() => ({
  ...props.vehicle,
  dedication: dedication.value || null,
  launchedOn: launchedOn.value || null,
  launchPort: launchPort.value || null,
  affiliation: affiliation.value || null,
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
// so it is only sent once picked: otherwise saving any line would pin the
// default as a choice of its own.
const initialPlaqueStyle = plaqueStyle.value;

const onSubmit = handleSubmit(async (values) => {
  await updateMutation
    .mutateAsync({
      id: props.vehicle.id,
      // Null rather than left out: a cleared field clears the line.
      data: {
        dedication: values.dedication || null,
        launchedOn: values.launchedOn || null,
        launchPort: values.launchPort || null,
        launchPortLocationId: values.launchPortLocationId ?? null,
        affiliation: values.affiliation || null,
        operationsGroup: values.operationsGroup || null,
        ...(values.plaqueStyle !== initialPlaqueStyle
          ? { plaqueStyle: values.plaqueStyle || null }
          : {}),
      },
    })
    .then(() => comlink.emit("close-modal"))
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
          <p
            v-if="!isSupporter"
            class="plaque-edit__upsell"
            data-test="vehicle-plaque-upsell"
          >
            {{ t("texts.vehiclePlaque.supporter") }}
            <router-link
              :to="{ name: 'support' }"
              @click="comlink.emit('close-modal')"
            >
              {{ t("actions.supportUs") }}
            </router-link>
          </p>
          <div class="plaque-edit__styles" data-test="vehicle-plaque-style">
            <button
              v-for="option in plaqueStyleOptions"
              :key="option.value"
              v-tooltip="
                option.locked
                  ? t('labels.vehiclePlaque.supporterStyle')
                  : undefined
              "
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
                :captain="currentUser?.username"
              />
              <span class="plaque-edit__style-label">
                <i v-if="option.locked" class="fa-light fa-lock" />
                {{ option.label }}
              </span>
            </button>
          </div>
        </div>
        <div v-else key="details">
          <VehiclePlaque
            :vehicle="preview"
            :captain="currentUser?.username"
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
              <FormDatePicker
                v-model="launchedOn"
                name="launchedOn"
                :label="t('labels.vehiclePlaque.launchedOn')"
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

    <template #footer>
      <Btn
        v-if="stylesOpen"
        :size="BtnSizesEnum.LG"
        :variant="BtnVariantsEnum.BARE"
        class="plaque-edit__footer-start"
        data-test="vehicle-plaque-styles-back"
        @click="stylesOpen = false"
      >
        <i class="fa-light fa-chevron-left" />
        {{ t("actions.back") }}
      </Btn>
      <template v-else>
        <Btn
          :size="BtnSizesEnum.LG"
          :variant="BtnVariantsEnum.BARE"
          class="plaque-edit__footer-start"
          data-test="vehicle-plaque-styles-open"
          @click="stylesOpen = true"
        >
          <i class="fa-light fa-palette" />
          {{ t("labels.vehiclePlaque.style") }}
        </Btn>
        <Btn
          :type="BtnTypesEnum.SUBMIT"
          form="vehicle-plaque-form"
          :loading="updateMutation.isPending.value"
          data-test="vehicle-plaque-save"
        >
          {{ t("actions.save") }}
        </Btn>
      </template>
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

  &--locked {
    cursor: not-allowed;

    :deep(.vehicle-plaque-frame) {
      opacity: 0.45;
      filter: grayscale(0.6);
    }
  }
}

.plaque-edit__style-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.85rem;
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

.plaque-edit__footer-start {
  margin-right: auto;
}

.plaque-edit__upsell {
  margin: 0 0 14px;
}

.plaque-edit__preview {
  margin-bottom: 20px;
}

.plaque-edit__fleets {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  margin: -8px 0 16px;
}
</style>

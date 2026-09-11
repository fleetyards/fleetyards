<script lang="ts">
export default {
  name: "AdminModelEditMetricsPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type ModelExtended,
  type ModelUpdateInput,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import ModelForm from "@/admin/components/Models/Form/index.vue";
import { InputAlignmentsEnum } from "@/shared/components/base/FormInput/types";
import ModelSizeSelect from "@/frontend/components/base/ModelSizeSelect/index.vue";
import ModelDockSizeSelect from "@/admin/components/base/ModelDockSizeSelect/index.vue";
import ModelVehicleSizeSelect from "@/admin/components/base/ModelVehicleSizeSelect/index.vue";
import { hasDrifted, isAppliable } from "@/admin/utils/DimensionDrift";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

const initialValues = ref<ModelUpdateInput>({
  size: props.model.metrics.size,
  dockSize: props.model.metrics.dockSize,
  length: props.model.metrics.length,
  beam: props.model.metrics.beam,
  height: props.model.metrics.height,
  fleetchartOffsetLength: props.model.metrics.fleetchartOffsetLength,
  fleetchartOffsetBeam: props.model.metrics.fleetchartOffsetBeam,
  extendedLength: props.model.metrics.extendedLength,
  extendedBeam: props.model.metrics.extendedBeam,
  extendedHeight: props.model.metrics.extendedHeight,
  extendedFleetchartOffsetLength:
    props.model.metrics.extendedFleetchartOffsetLength,
  extendedFleetchartOffsetBeam:
    props.model.metrics.extendedFleetchartOffsetBeam,
  mass: props.model.metrics.mass,
  minCrew: props.model.crew.min,
  maxCrew: props.model.crew.max,
  scmSpeed: props.model.speeds.scmSpeed,
  scmSpeedBoosted: props.model.speeds.scmSpeedBoosted,
  maxSpeed: props.model.speeds.maxSpeed,
  reverseSpeedBoosted: props.model.speeds.reverseSpeedBoosted,
  pitch: props.model.speeds.pitch,
  yaw: props.model.speeds.yaw,
  roll: props.model.speeds.roll,
  pitchBoosted: props.model.speeds.pitchBoosted,
  yawBoosted: props.model.speeds.yawBoosted,
  rollBoosted: props.model.speeds.rollBoosted,
});

const validationSchema = {};

const { defineField, handleSubmit, meta } = useForm<ModelUpdateInput>({
  initialValues: initialValues.value,
  validationSchema,
});

const [size, sizeProps] = defineField("size");
const [vehicleSize, vehicleSizeProps] = defineField("vehicleSize");
const [dockSize, dockSizeProps] = defineField("dockSize");
const [length, lengthProps] = defineField("length");
const [fleetchartOffsetLength, fleetchartOffsetLengthProps] = defineField(
  "fleetchartOffsetLength",
);
const [fleetchartOffsetBeam, fleetchartOffsetBeamProps] = defineField(
  "fleetchartOffsetBeam",
);
const [extendedLength, extendedLengthProps] = defineField("extendedLength");
const [extendedBeam, extendedBeamProps] = defineField("extendedBeam");
const [extendedHeight, extendedHeightProps] = defineField("extendedHeight");
const [extendedFleetchartOffsetLength, extendedFleetchartOffsetLengthProps] =
  defineField("extendedFleetchartOffsetLength");
const [extendedFleetchartOffsetBeam, extendedFleetchartOffsetBeamProps] =
  defineField("extendedFleetchartOffsetBeam");
const [beam, beamProps] = defineField("beam");
const [height, heightProps] = defineField("height");

// `sc_*` is what the loader read from the game files and rewrites on every
// import; the fields above are what `Dock#fits?` and the public payload use,
// and nothing keeps the two in step. A difference is worth looking at but not
// automatically wrong -- the Hull C is deliberately recorded expanded -- so it
// is shown and taken over one field at a time.
const lengthDrifted = computed(() =>
  hasDrifted(length.value, props.model.scLength),
);
const beamDrifted = computed(() => hasDrifted(beam.value, props.model.scBeam));
const heightDrifted = computed(() =>
  hasDrifted(height.value, props.model.scHeight),
);

const lengthAppliable = computed(() =>
  isAppliable(length.value, props.model.scLength),
);
const beamAppliable = computed(() =>
  isAppliable(beam.value, props.model.scBeam),
);
const heightAppliable = computed(() =>
  isAppliable(height.value, props.model.scHeight),
);

const anyAppliable = computed(
  () => lengthAppliable.value || beamAppliable.value || heightAppliable.value,
);

const anyDrifted = computed(
  () => lengthDrifted.value || beamDrifted.value || heightDrifted.value,
);

const applyScDimensions = () => {
  if (props.model.scLength !== null && props.model.scLength !== undefined) {
    length.value = props.model.scLength;
  }
  if (props.model.scBeam !== null && props.model.scBeam !== undefined) {
    beam.value = props.model.scBeam;
  }
  if (props.model.scHeight !== null && props.model.scHeight !== undefined) {
    height.value = props.model.scHeight;
  }
};
const [mass, massProps] = defineField("mass");
const [minCrew, minCrewProps] = defineField("minCrew");
const [maxCrew, maxCrewProps] = defineField("maxCrew");
const [scmSpeed, scmSpeedProps] = defineField("scmSpeed");
const [scmSpeedBoosted, scmSpeedBoostedProps] = defineField("scmSpeedBoosted");
const [maxSpeed, maxSpeedProps] = defineField("maxSpeed");
const [reverseSpeedBoosted, reverseSpeedBoostedProps] = defineField(
  "reverseSpeedBoosted",
);
const [pitch, pitchProps] = defineField("pitch");
const [yaw, yawProps] = defineField("yaw");
const [roll, rollProps] = defineField("roll");
const [pitchBoosted, pitchBoostedProps] = defineField("pitchBoosted");
const [yawBoosted, yawBoostedProps] = defineField("yawBoosted");
const [rollBoosted, rollBoostedProps] = defineField("rollBoosted");
</script>

<template>
  <Heading hero>{{ t("headlines.admin.models.edit.metrics") }}</Heading>
  <ModelForm :model="model" :handle-submit="handleSubmit" :meta="meta">
    <div class="row">
      <div class="col-12 col-md-4">
        <ModelSizeSelect
          v-model="size"
          v-bind="sizeProps"
          :no-label="false"
          :multiple="false"
          name="size"
        />
      </div>
      <div class="col-12 col-md-4">
        <ModelVehicleSizeSelect
          v-model="vehicleSize"
          v-bind="vehicleSizeProps"
          :no-label="false"
          :multiple="false"
          name="vehicleSize"
        />
      </div>
      <div class="col-12 col-md-4">
        {{ model.metrics.dockSize }}
        <ModelDockSizeSelect
          v-model="dockSize"
          v-bind="dockSizeProps"
          :no-label="false"
          :multiple="false"
          name="dockSize"
        />
      </div>
    </div>
    <hr />
    <div v-if="anyDrifted" class="metrics__drift-notice">
      <i class="fa-duotone fa-triangle-exclamation" />
      <span>{{ t("messages.model.dimensionsDrifted") }}</span>
      <button
        v-if="anyAppliable"
        type="button"
        class="metrics__apply"
        @click="applyScDimensions"
      >
        {{ t("actions.applyAllGameFileValues") }}
      </button>
    </div>
    <div class="row">
      <div class="col-12 col-md-4">
        <FormInput
          v-model="length"
          v-bind="lengthProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="length"
          translation-key="model.length"
          :suffix="t('number.units.distance')"
        >
          <template #subline>
            <span :class="{ 'metrics__sc--drifted': lengthDrifted }">
              SC Length: {{ model.scLength ?? "—" }}
            </span>
            <button
              v-if="lengthAppliable"
              type="button"
              class="metrics__apply"
              @click="length = model.scLength"
            >
              {{ t("actions.applyGameFileValue") }}
            </button>
          </template>
        </FormInput>
      </div>
      <div class="col-12 col-md-4">
        <FormInput
          v-model="beam"
          v-bind="beamProps"
          name="beam"
          :alignment="InputAlignmentsEnum.RIGHT"
          translation-key="model.beam"
          :suffix="t('number.units.distance')"
        >
          <template #subline>
            <span :class="{ 'metrics__sc--drifted': beamDrifted }">
              SC Beam: {{ model.scBeam ?? "—" }}
            </span>
            <button
              v-if="beamAppliable"
              type="button"
              class="metrics__apply"
              @click="beam = model.scBeam"
            >
              {{ t("actions.applyGameFileValue") }}
            </button>
          </template>
        </FormInput>
      </div>
      <div class="col-12 col-md-4">
        <FormInput
          v-model="height"
          v-bind="heightProps"
          name="height"
          :alignment="InputAlignmentsEnum.RIGHT"
          translation-key="model.height"
          :suffix="t('number.units.distance')"
        >
          <template #subline>
            <span :class="{ 'metrics__sc--drifted': heightDrifted }">
              SC Height: {{ model.scHeight ?? "—" }}
            </span>
            <button
              v-if="heightAppliable"
              type="button"
              class="metrics__apply"
              @click="height = model.scHeight"
            >
              {{ t("actions.applyGameFileValue") }}
            </button>
          </template>
        </FormInput>
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-4">
        <FormInput
          v-model="fleetchartOffsetLength"
          v-bind="fleetchartOffsetLengthProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="fleetchartOffsetLength"
          translation-key="model.fleetchartOffsetLength"
          :suffix="t('number.units.distance')"
        />
      </div>
      <div class="col-12 col-md-4">
        <FormInput
          v-model="fleetchartOffsetBeam"
          v-bind="fleetchartOffsetBeamProps"
          name="fleetchartOffsetBeam"
          :alignment="InputAlignmentsEnum.RIGHT"
          translation-key="model.fleetchartOffsetBeam"
          :suffix="t('number.units.distance')"
        />
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12 col-md-4">
        <FormInput
          v-model="extendedLength"
          v-bind="extendedLengthProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="extendedLength"
          translation-key="model.extendedLength"
          :suffix="t('number.units.distance')"
        />
      </div>
      <div class="col-12 col-md-4">
        <FormInput
          v-model="extendedBeam"
          v-bind="extendedBeamProps"
          name="extendedBeam"
          :alignment="InputAlignmentsEnum.RIGHT"
          translation-key="model.extendedBeam"
          :suffix="t('number.units.distance')"
        />
      </div>
      <div class="col-12 col-md-4">
        <FormInput
          v-model="extendedHeight"
          v-bind="extendedHeightProps"
          name="extendedHeight"
          :alignment="InputAlignmentsEnum.RIGHT"
          translation-key="model.extendedHeight"
          :suffix="t('number.units.distance')"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-4">
        <FormInput
          v-model="extendedFleetchartOffsetLength"
          v-bind="extendedFleetchartOffsetLengthProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="extendedFleetchartOffsetLength"
          translation-key="model.extendedFleetchartOffsetLength"
          :suffix="t('number.units.distance')"
        />
      </div>
      <div class="col-12 col-md-4">
        <FormInput
          v-model="extendedFleetchartOffsetBeam"
          v-bind="extendedFleetchartOffsetBeamProps"
          name="extendedFleetchartOffsetBeam"
          :alignment="InputAlignmentsEnum.RIGHT"
          translation-key="model.extendedFleetchartOffsetBeam"
          :suffix="t('number.units.distance')"
        />
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12 col-md-4">
        <FormInput
          v-model="mass"
          v-bind="massProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="mass"
          translation-key="model.mass"
          :suffix="t('number.units.weight')"
        />
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12 col-md-4">
        <FormInput
          v-model="minCrew"
          v-bind="minCrewProps"
          name="minCrew"
          :alignment="InputAlignmentsEnum.RIGHT"
          translation-key="model.minCrew"
          :suffix="t('number.units.person')"
        />
      </div>
      <div class="col-12 col-md-4">
        <FormInput
          v-model="maxCrew"
          v-bind="maxCrewProps"
          name="maxCrew"
          :alignment="InputAlignmentsEnum.RIGHT"
          translation-key="model.maxCrew"
          :suffix="t('number.units.person')"
        />
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12 col-md-4">
        <FormInput
          v-model="scmSpeed"
          v-bind="scmSpeedProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="scmSpeed"
          translation-key="model.scmSpeed"
          :suffix="t('number.units.speed')"
        />
      </div>
      <div class="col-12 col-md-4">
        <FormInput
          v-model="scmSpeedBoosted"
          v-bind="scmSpeedBoostedProps"
          name="scmSpeedBoosted"
          :alignment="InputAlignmentsEnum.RIGHT"
          translation-key="model.scmSpeedBoosted"
          :suffix="t('number.units.speed')"
        />
      </div>
      <div class="col-12 col-md-4">
        <FormInput
          v-model="maxSpeed"
          v-bind="maxSpeedProps"
          name="maxSpeed"
          :alignment="InputAlignmentsEnum.RIGHT"
          translation-key="model.maxSpeed"
          :suffix="t('number.units.speed')"
        />
      </div>
      <div class="col-12 col-md-4">
        <FormInput
          v-model="reverseSpeedBoosted"
          v-bind="reverseSpeedBoostedProps"
          name="reverseSpeedBoosted"
          :alignment="InputAlignmentsEnum.RIGHT"
          translation-key="model.reverseSpeedBoosted"
          :suffix="t('number.units.speed')"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-4">
        <FormInput
          v-model="pitch"
          v-bind="pitchProps"
          name="pitch"
          :alignment="InputAlignmentsEnum.RIGHT"
          translation-key="model.pitch"
          :suffix="t('number.units.speed')"
        />
      </div>
      <div class="col-12 col-md-4">
        <FormInput
          v-model="yaw"
          v-bind="yawProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="yaw"
          translation-key="model.yaw"
          :suffix="t('number.units.speed')"
        />
      </div>
      <div class="col-12 col-md-4">
        <FormInput
          v-model="roll"
          v-bind="rollProps"
          name="roll"
          :alignment="InputAlignmentsEnum.RIGHT"
          translation-key="model.roll"
          :suffix="t('number.units.speed')"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-4">
        <FormInput
          v-model="pitchBoosted"
          v-bind="pitchBoostedProps"
          name="pitchBoosted"
          :alignment="InputAlignmentsEnum.RIGHT"
          translation-key="model.pitchBoosted"
          :suffix="t('number.units.speed')"
        />
      </div>
      <div class="col-12 col-md-4">
        <FormInput
          v-model="yawBoosted"
          v-bind="yawBoostedProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="yawBoosted"
          translation-key="model.yawBoosted"
          :suffix="t('number.units.speed')"
        />
      </div>
      <div class="col-12 col-md-4">
        <FormInput
          v-model="rollBoosted"
          v-bind="rollBoostedProps"
          name="rollBoosted"
          :alignment="InputAlignmentsEnum.RIGHT"
          translation-key="model.rollBoosted"
          :suffix="t('number.units.speed')"
        />
      </div>
    </div>
  </ModelForm>
</template>

<style lang="scss" scoped>
.metrics__drift-notice {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-wrap: wrap;
  margin-bottom: 1rem;
}

.metrics__sc--drifted {
  font-weight: 600;
}

.metrics__apply {
  background: none;
  border: none;
  padding: 0;
  cursor: pointer;
  text-decoration: underline;
  font: inherit;
  color: inherit;
}
</style>

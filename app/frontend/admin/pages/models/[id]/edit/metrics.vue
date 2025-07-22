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
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { InputAlignmentsEnum } from "@/shared/components/base/FormInput/types";
import ModelSizeFilterGroup from "@/frontend/components/base/ModelSizeFilterGroup/index.vue";
import ModelDockSizeFilterGroup from "@/admin/components/base/ModelDockSizeFilterGroup/index.vue";
// import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

// const { displayAlert } = useAppNotifications();

const submitting = ref(false);

const initialValues = ref<ModelUpdateInput>({
  size: props.model.metrics.size,
  dockSize: props.model.metrics.dockSize,
  length: props.model.metrics.length,
  beam: props.model.metrics.beam,
  height: props.model.metrics.height,
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

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
  validationSchema,
});

const [size, sizeProps] = defineField("size");
const [dockSize, dockSizeProps] = defineField("dockSize");
const [length, lengthProps] = defineField("length");
const [beam, beamProps] = defineField("beam");
const [height, heightProps] = defineField("height");
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

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;
  console.info(values);
});

const onCancel = () => {
  alert("cancel");
};
</script>

<template>
  <Heading>{{ t("headlines.admin.models.edit.metrics") }}</Heading>
  <form @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-4">
        <ModelSizeFilterGroup
          v-model="size"
          v-bind="sizeProps"
          :no-label="false"
          :multiple="false"
          name="size"
        />
      </div>
      <div class="col-12 col-md-4">
        {{ model.metrics.dockSize }}
        <ModelDockSizeFilterGroup
          v-model="dockSize"
          v-bind="dockSizeProps"
          :no-label="false"
          :multiple="false"
          name="dockSize"
        />
      </div>
    </div>
    <hr />
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
          <template #subline>SC Length: {{ model.scLength }}</template>
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
          <template #subline>SC Beam: {{ model.scBeam }}</template>
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
          <template #subline>SC Height: {{ model.scHeight }}</template>
        </FormInput>
      </div>
    </div>
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
    <FormActions :submitting="submitting" @cancel="onCancel" />
  </form>
</template>

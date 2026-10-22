<script lang="ts">
export default {
  name: "VehiclePlaqueFields",
};
</script>

<script lang="ts" setup>
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormDatePicker from "@/shared/components/base/FormDatePicker/index.vue";
import LocationInput from "@/shared/components/LocationInput/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { OPERATIONS_GROUPS } from "@/frontend/components/Vehicles/Plaque/operationsGroups";
import { IN_UNIVERSE_YEAR_OFFSET } from "@/frontend/components/Vehicles/Plaque/launchDate";
import {
  PLAQUE_FIELD_RULES,
  PLAQUE_LIMITS,
} from "@/frontend/components/Vehicles/PlaqueFields/rules";
import { useI18n } from "@/shared/composables/useI18n";
import { type LocationLink } from "@/services/fyApi";

type Props = {
  // The starmap location the launch port was saved linked to.
  linkedLaunchPort?: LocationLink | null;
  // The plaque's captain when none is written in.
  captainPlaceholder?: string;
  // Offered as the organization the ship serves.
  fleetNames?: string[];
};

withDefaults(defineProps<Props>(), {
  linkedLaunchPort: undefined,
  captainPlaceholder: undefined,
  fleetNames: () => [],
});

const dedication = defineModel<string>("dedication");
const dedicationVerse = defineModel<string>("dedicationVerse");
const launchedOn = defineModel<string | null>("launchedOn");
const launchPort = defineModel<string>("launchPort");
const launchPortLocationId = defineModel<string | null>("launchPortLocationId");
const affiliation = defineModel<string>("affiliation");
const plaqueCaptain = defineModel<string>("plaqueCaptain");
const operationsGroup = defineModel<string | null>("operationsGroup");

const { t } = useI18n();

// Grouped by side of the law, lawful first, as the select keeps this order.
const operationsGroupOptions = computed(() =>
  Object.entries(OPERATIONS_GROUPS).map(([value, group]) => ({
    value,
    label: `${group.name} · ${t(`labels.fleet.alignments.${group.alignment}`)}`,
  })),
);
</script>

<template>
  <div class="plaque-fields">
    <div>
      <FormTextarea
        v-model="dedication"
        name="dedication"
        :label="t('labels.vehiclePlaque.dedication')"
        :rules="PLAQUE_FIELD_RULES.dedication"
        :maxlength="PLAQUE_LIMITS.dedication"
        data-test="vehicle-plaque-dedication-input"
      />
      <FormTextarea
        v-model="dedicationVerse"
        name="dedicationVerse"
        :label="t('labels.vehiclePlaque.dedicationVerse')"
        :info="t('labels.vehiclePlaque.dedicationVerseInfo')"
        :rules="PLAQUE_FIELD_RULES.dedicationVerse"
        :maxlength="PLAQUE_LIMITS.dedicationVerse"
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
        :linked="linkedLaunchPort"
        name="launchPort"
        :label="t('labels.vehiclePlaque.launchPort')"
        :rules="PLAQUE_FIELD_RULES.launchPort"
      />
      <FormInput
        v-model="plaqueCaptain"
        name="plaqueCaptain"
        :label="t('labels.vehiclePlaque.captain')"
        :info="t('labels.vehiclePlaque.captainInfo')"
        :placeholder="captainPlaceholder"
        :rules="PLAQUE_FIELD_RULES.plaqueCaptain"
        data-test="vehicle-plaque-captain-input"
      />
      <FormInput
        v-model="affiliation"
        name="affiliation"
        :label="t('labels.vehiclePlaque.affiliation')"
        :rules="PLAQUE_FIELD_RULES.affiliation"
      />
      <div v-if="fleetNames.length" class="plaque-fields__fleets">
        <span class="text-muted">{{ t("texts.vehiclePlaque.fromFleet") }}</span>
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
</template>

<style lang="scss" scoped>
// Two columns of fields; one on a narrow screen.
.plaque-fields {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0 24px;

  @media (max-width: $tablet-breakpoint) {
    grid-template-columns: minmax(0, 1fr);
  }
}

.plaque-fields__fleets {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  margin: -8px 0 16px;
}
</style>

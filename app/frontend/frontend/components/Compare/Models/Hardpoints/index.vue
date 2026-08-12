<script lang="ts">
export default {
  name: "ModelsCompareHardpoints",
};
</script>

<script lang="ts" setup>
import CompareSection from "@/frontend/components/Compare/Models/Section/index.vue";
import CompareContentRow from "@/frontend/components/Compare/Models/ContentRow/index.vue";
import HardpointGroup from "@/frontend/components/Models/Hardpoints/Group/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  HardpointGroupEnum,
  type Hardpoint,
  type Model,
} from "@/services/fyApi";

type Props = {
  models: Model[];
  hardpointsFor: (model: Model) => Hardpoint[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const groups = [
  HardpointGroupEnum.AVIONIC,
  HardpointGroupEnum.SYSTEM,
  HardpointGroupEnum.PROPULSION,
  HardpointGroupEnum.THRUSTER,
  HardpointGroupEnum.WEAPON,
  HardpointGroupEnum.DEFENSE,
  HardpointGroupEnum.AUXILIARY,
  HardpointGroupEnum.EXTERNAL_FUEL_TANK,
  HardpointGroupEnum.OTHER,
];

const hardpointsForGroup = (group: HardpointGroupEnum, model: Model) =>
  props.hardpointsFor(model).filter((hardpoint) => hardpoint.group === group);

const visibleGroups = computed(() =>
  groups.filter((group) =>
    props.models.some((model) => hardpointsForGroup(group, model).length > 0),
  ),
);
</script>

<template>
  <CompareSection
    v-for="group in visibleGroups"
    :id="`compare-hardpoints-${group.toLowerCase()}`"
    :key="group"
    :title="t(`labels.hardpoint.groups.${group.toLowerCase()}`)"
  >
    <CompareContentRow :models="models" align="start">
      <template #default="{ model }">
        <HardpointGroup
          v-if="hardpointsForGroup(group, model).length > 0"
          :group="group"
          :hardpoints="hardpointsForGroup(group, model)"
          without-title
        />
      </template>
    </CompareContentRow>
  </CompareSection>
</template>

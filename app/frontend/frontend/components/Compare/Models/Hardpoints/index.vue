<script lang="ts">
export default {
  name: "ModelsCompareHardpoints",
};
</script>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import CompareModelsRow from "@/frontend/components/Compare/Models/Row/index.vue";
import CompareModelsRowTitle from "@/frontend/components/Compare/Models/Row/Title/index.vue";
import HardpointGroup from "@/frontend/components/Models/Hardpoints/Group/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Model,
  type Hardpoint,
  HardpointSourceEnum,
  HardpointGroupEnum,
  modelHardpoints as fetchModelHardpoints,
} from "@/services/fyApi";

type Props = {
  models: Model[];
  slim?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  slim: false,
});

const { t } = useI18n();

const hardpoints = ref<{ slug: string; hardpoints: Hardpoint[] }[]>([]);

const groups = [
  HardpointGroupEnum.AVIONIC,
  HardpointGroupEnum.SYSTEM,
  HardpointGroupEnum.PROPULSION,
  HardpointGroupEnum.THRUSTER,
  HardpointGroupEnum.WEAPON,
  HardpointGroupEnum.AUXILIARY,
  HardpointGroupEnum.OTHER,
];

const avionicVisible = ref(false);

const systemVisible = ref(false);

const propulsionVisible = ref(false);

const thrusterVisible = ref(false);

const weaponVisible = ref(false);

const auxiliaryVisible = ref(false);

const otherVisible = ref(false);

watch(
  () => props.models,
  async () => {
    setupVisibles();
    await fetch();
  },
);

onMounted(async () => {
  await fetch();
  setupVisibles();
});

const fetch = async () => {
  const promises = props.models.map((model) => {
    return fetchHardpoints(model);
  });

  hardpoints.value = await Promise.all(promises);
};

const fetchHardpoints = async (model: Model) => {
  const hardpoints = await fetchModelHardpoints(model.slug, {
    source: model.scIdentifier
      ? HardpointSourceEnum.GAME_FILES
      : HardpointSourceEnum.SHIP_MATRIX,
  });

  return {
    slug: model.slug,
    hardpoints: hardpoints as Hardpoint[],
  };
};

const setupVisibles = () => {
  avionicVisible.value = props.models.length > 0;
  systemVisible.value = props.models.length > 0;
  propulsionVisible.value = props.models.length > 0;
  thrusterVisible.value = props.models.length > 0;
  weaponVisible.value = props.models.length > 0;
  auxiliaryVisible.value = props.models.length > 0;
  otherVisible.value = props.models.length > 0;
};

const isVisible = (group: HardpointGroupEnum) => {
  if (group === HardpointGroupEnum.AVIONIC) {
    return avionicVisible.value;
  }
  if (group === HardpointGroupEnum.SYSTEM) {
    return systemVisible.value;
  }
  if (group === HardpointGroupEnum.PROPULSION) {
    return propulsionVisible.value;
  }
  if (group === HardpointGroupEnum.THRUSTER) {
    return thrusterVisible.value;
  }
  if (group === HardpointGroupEnum.WEAPON) {
    return weaponVisible.value;
  }
  if (group === HardpointGroupEnum.AUXILIARY) {
    return auxiliaryVisible.value;
  }
  if (group === HardpointGroupEnum.OTHER) {
    return otherVisible.value;
  }

  return false;
};

const toggle = (group: HardpointGroupEnum) => {
  if (group === HardpointGroupEnum.AVIONIC) {
    avionicVisible.value = !avionicVisible.value;
  }
  if (group === HardpointGroupEnum.SYSTEM) {
    systemVisible.value = !systemVisible.value;
  }
  if (group === HardpointGroupEnum.PROPULSION) {
    propulsionVisible.value = !propulsionVisible.value;
  }
  if (group === HardpointGroupEnum.THRUSTER) {
    thrusterVisible.value = !thrusterVisible.value;
  }
  if (group === HardpointGroupEnum.WEAPON) {
    weaponVisible.value = !weaponVisible.value;
  }
  if (group === HardpointGroupEnum.AUXILIARY) {
    auxiliaryVisible.value = !auxiliaryVisible.value;
  }
  if (group === HardpointGroupEnum.OTHER) {
    otherVisible.value = !otherVisible.value;
  }
};

const hardpointsForGroup = (
  group: HardpointGroupEnum,
  hardpoints: Hardpoint[],
) => (hardpoints || []).filter((hardpoint) => hardpoint.group === group);

const hardpointsForModel = (model: Model) => {
  const hardpoint = hardpoints.value.find((h) => h.slug === model.slug);
  return hardpoint ? hardpoint.hardpoints : [];
};
</script>

<template>
  <div v-for="group in groups" :key="group">
    <CompareModelsRow
      :models="models"
      :row-key="group"
      :slim="slim"
      sticky-left
      section
    >
      <template #label>
        <CompareModelsRowTitle
          :active="isVisible(group)"
          :title="t(`labels.hardpoint.groups.${group.toLowerCase()}`)"
          @click="toggle(group)"
        />
      </template>
    </CompareModelsRow>

    <Collapsed :id="group" :visible="isVisible(group)" class="row">
      <div class="col-12">
        <CompareModelsRow
          :models="models"
          :row-key="group"
          :slim="slim"
          sticky-left
        >
          <template #default="{ model }">
            <HardpointGroup
              v-if="
                hardpointsForGroup(group, hardpointsForModel(model)).length > 0
              "
              :group="group"
              :hardpoints="hardpointsForGroup(group, hardpointsForModel(model))"
              without-title
            />
          </template>
        </CompareModelsRow>
      </div>
    </Collapsed>
  </div>
</template>

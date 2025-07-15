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
  HardpointGroupEnum.avionic,
  HardpointGroupEnum.system,
  HardpointGroupEnum.propulsion,
  HardpointGroupEnum.thruster,
  HardpointGroupEnum.weapon,
  HardpointGroupEnum.auxiliary,
  HardpointGroupEnum.other,
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
      ? HardpointSourceEnum.game_files
      : HardpointSourceEnum.ship_matrix,
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
  if (group === HardpointGroupEnum.avionic) {
    return avionicVisible.value;
  }
  if (group === HardpointGroupEnum.system) {
    return systemVisible.value;
  }
  if (group === HardpointGroupEnum.propulsion) {
    return propulsionVisible.value;
  }
  if (group === HardpointGroupEnum.thruster) {
    return thrusterVisible.value;
  }
  if (group === HardpointGroupEnum.weapon) {
    return weaponVisible.value;
  }
  if (group === HardpointGroupEnum.auxiliary) {
    return auxiliaryVisible.value;
  }
  if (group === HardpointGroupEnum.other) {
    return otherVisible.value;
  }

  return false;
};

const toggle = (group: HardpointGroupEnum) => {
  if (group === HardpointGroupEnum.avionic) {
    avionicVisible.value = !avionicVisible.value;
  }
  if (group === HardpointGroupEnum.system) {
    systemVisible.value = !systemVisible.value;
  }
  if (group === HardpointGroupEnum.propulsion) {
    propulsionVisible.value = !propulsionVisible.value;
  }
  if (group === HardpointGroupEnum.thruster) {
    thrusterVisible.value = !thrusterVisible.value;
  }
  if (group === HardpointGroupEnum.weapon) {
    weaponVisible.value = !weaponVisible.value;
  }
  if (group === HardpointGroupEnum.auxiliary) {
    auxiliaryVisible.value = !auxiliaryVisible.value;
  }
  if (group === HardpointGroupEnum.other) {
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

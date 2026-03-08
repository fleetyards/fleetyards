<script lang="ts">
export default {
  name: "ModelsCompareHardpointsOld",
};
</script>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import CompareModelsRow from "@/frontend/components/Compare/Models/Row/index.vue";
import CompareModelsRowTitle from "@/frontend/components/Compare/Models/Row/Title/index.vue";
import HardpointGroup from "@/frontend/components/Models/Hardpoints/old/Group/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  modelHardpoints as fetchModelHardpoints,
  HardpointSourceEnum,
  ModelHardpointGroupEnum,
  type Model,
  type ModelHardpoint,
} from "@/services/fyApi";

type Props = {
  models: Model[];
  slim?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  slim: false,
});

const { t } = useI18n();

const hardpoints = ref<{ slug: string; hardpoints: ModelHardpoint[] }[]>([]);

const groups = [
  ModelHardpointGroupEnum.AVIONIC,
  ModelHardpointGroupEnum.SYSTEM,
  ModelHardpointGroupEnum.PROPULSION,
  ModelHardpointGroupEnum.THRUSTER,
  ModelHardpointGroupEnum.WEAPON,
];

const avionicVisible = ref(false);

const systemVisible = ref(false);

const propulsionVisible = ref(false);

const thrusterVisible = ref(false);

const weaponVisible = ref(false);

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
    hardpoints: hardpoints as ModelHardpoint[],
  };
};

const setupVisibles = () => {
  avionicVisible.value = props.models.length > 0;
  systemVisible.value = props.models.length > 0;
  propulsionVisible.value = props.models.length > 0;
  thrusterVisible.value = props.models.length > 0;
  weaponVisible.value = props.models.length > 0;
};

const isVisible = (group: ModelHardpointGroupEnum) => {
  if (group === ModelHardpointGroupEnum.AVIONIC) {
    return avionicVisible.value;
  }
  if (group === ModelHardpointGroupEnum.SYSTEM) {
    return systemVisible.value;
  }
  if (group === ModelHardpointGroupEnum.PROPULSION) {
    return propulsionVisible.value;
  }
  if (group === ModelHardpointGroupEnum.THRUSTER) {
    return thrusterVisible.value;
  }
  if (group === ModelHardpointGroupEnum.WEAPON) {
    return weaponVisible.value;
  }

  return false;
};

const toggle = (group: ModelHardpointGroupEnum) => {
  if (group === ModelHardpointGroupEnum.AVIONIC) {
    avionicVisible.value = !avionicVisible.value;
  }
  if (group === ModelHardpointGroupEnum.SYSTEM) {
    systemVisible.value = !systemVisible.value;
  }
  if (group === ModelHardpointGroupEnum.PROPULSION) {
    propulsionVisible.value = !propulsionVisible.value;
  }
  if (group === ModelHardpointGroupEnum.THRUSTER) {
    thrusterVisible.value = !thrusterVisible.value;
  }
  if (group === ModelHardpointGroupEnum.WEAPON) {
    weaponVisible.value = !weaponVisible.value;
  }
};

const hardpointsForGroup = (
  group: ModelHardpointGroupEnum,
  hardpoints: ModelHardpoint[],
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
      :row-key="`${group}-title`"
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
      <div class="col-12 hardpoints-legacy">
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

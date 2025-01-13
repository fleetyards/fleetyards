<script lang="ts">
export default {
  name: "ModelsCompareHardpointsOld",
};
</script>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import HardpointGroup from "@/frontend/components/Models/Hardpoints/old/Group/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Model,
  type ModelHardpoint,
  HardpointSourceEnum,
  ModelHardpointGroupEnum,
} from "@/services/fyApi";
import { useApiClient } from "@/frontend/composables/useApiClient";

type Props = {
  models: Model[];
};

const props = defineProps<Props>();

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

const { models: modelsService } = useApiClient();

const fetch = async () => {
  const promises = props.models.map((model) => {
    return fetchHardpoints(model);
  });

  hardpoints.value = await Promise.all(promises);
};

const fetchHardpoints = async (model: Model) => {
  const hardpoints = await modelsService.modelHardpoints({
    slug: model.slug,
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
</script>

<template>
  <div>
    <div v-for="group in groups" :key="group">
      <div class="row compare-row compare-section">
        <div class="col-12 compare-row-label sticky-left">
          <div
            :class="{
              active: isVisible(group),
            }"
            class="text-right metrics-title"
            @click="toggle(group)"
          >
            {{ t(`labels.hardpoint.groups.${group.toLowerCase()}`) }}
            <i class="fa fa-chevron-right" />
          </div>
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-placeholder`"
          class="col-12 compare-row-item"
        />
      </div>

      <Collapsed :id="group" :visible="isVisible(group)" class="row">
        <div class="col-12">
          <div class="row compare-row">
            <div
              class="col-12 compare-row-label text-right metrics-label sticky-left"
            />
            <div
              v-for="model in hardpoints"
              :key="`${model.slug}-${group}`"
              class="col-6 compare-row-item"
            >
              <div class="well">
                <HardpointGroup
                  v-if="hardpointsForGroup(group, model.hardpoints).length > 0"
                  :group="group"
                  :hardpoints="hardpointsForGroup(group, model.hardpoints)"
                  without-title
                />
              </div>
            </div>
          </div>
        </div>
      </Collapsed>
    </div>
  </div>
</template>

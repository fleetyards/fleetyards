<script lang="ts">
export default {
  name: "ModelsCompareHardpoints",
};
</script>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import HardpointGroup from "@/frontend/components/Models/Hardpoints/Group/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Model,
  type Hardpoint,
  HardpointSourceEnum,
} from "@/services/fyApi";
import { HardpointGroupEnum } from "@/services/fyApi";
import { modelHardpoints as fetchModelHardpoints } from "@/services/fyApi";

type Props = {
  models: Model[];
};

const props = defineProps<Props>();

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

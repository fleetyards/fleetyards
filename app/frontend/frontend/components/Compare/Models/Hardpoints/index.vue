<template>
  <div>
    <div v-for="group in groups" :key="group">
      <div class="row compare-row compare-section">
        <div class="col-12 compare-row-label sticky-left">
          <div
            :class="{
              active: isVisible(group.toLowerCase()),
            }"
            class="text-right metrics-title"
            @click="toggle(group.toLowerCase())"
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

      <Collapsed
        :id="group"
        :visible="isVisible(group.toLowerCase())"
        class="row"
      >
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

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import HardpointGroup from "@/frontend/components/Models/Hardpoints/Group/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { Model, Hardpoint } from "@/services/fyApi";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { HardpointGroupEnum } from "@/services/fyAdminApi";

type Props = {
  models: Model[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const hardpoints = ref<{ slug: string; hardpoints: Hardpoint[] }[]>([]);

const groups = [
  HardpointGroupEnum.AVIONIC,
  HardpointGroupEnum.SYSTEM,
  HardpointGroupEnum.PROPULSION,
  HardpointGroupEnum.THRUSTER,
  HardpointGroupEnum.WEAPON,
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
    return fetchHardpoints(model.slug);
  });

  hardpoints.value = await Promise.all(promises);
};

const fetchHardpoints = async (slug: string) => {
  const hardpoints = await modelsService.modelHardpoints({
    slug: slug,
  });

  return {
    slug,
    hardpoints,
  };
};

const setupVisibles = () => {
  avionicVisible.value = props.models.length > 0;
  systemVisible.value = props.models.length > 0;
  propulsionVisible.value = props.models.length > 0;
  thrusterVisible.value = props.models.length > 0;
  weaponVisible.value = props.models.length > 0;
};

const isVisible = (group: string) => {
  if (group === "avionic") {
    return avionicVisible.value;
  }
  if (group === "system") {
    return systemVisible.value;
  }
  if (group === "propulsion") {
    return propulsionVisible.value;
  }
  if (group === "thruster") {
    return thrusterVisible.value;
  }
  if (group === "weapon") {
    return weaponVisible.value;
  }

  return false;
};

const toggle = (group: string) => {
  if (group === "avionic") {
    avionicVisible.value = !avionicVisible.value;
  }
  if (group === "system") {
    systemVisible.value = !systemVisible.value;
  }
  if (group === "propulsion") {
    propulsionVisible.value = !propulsionVisible.value;
  }
  if (group === "thruster") {
    thrusterVisible.value = !thrusterVisible.value;
  }
  if (group === "weapon") {
    weaponVisible.value = !weaponVisible.value;
  }
};

const hardpointsForGroup = (
  group: HardpointGroupEnum,
  hardpoints: Hardpoint[],
) => (hardpoints || []).filter((hardpoint) => hardpoint.group === group);
</script>

<script lang="ts">
export default {
  name: "ModelsCompareCategories",
};
</script>

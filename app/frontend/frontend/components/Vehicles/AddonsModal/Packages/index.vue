<template>
  <div class="row">
    <div v-for="item in packages" :key="item.id" class="col-12 col-md-6 addon">
      <Panel>
        <div
          v-tooltip="editable"
          class="model-panel"
          :class="{
            editable,
          }"
          @click="activatePackage(item)"
        >
          <div
            v-if="item.media.storeImage"
            :style="{
              'background-image': `url(${item.media.storeImage.small})`,
            }"
            class="model-panel-image"
          />
          <div class="model-panel-body">
            <h3>{{ item.name }}</h3>
          </div>
          <div
            v-if="selectedPackage(item)"
            v-tooltip="editable && t('labels.selected')"
            class="model-panel-selected"
          >
            <i class="fa fa-check" />
          </div>
        </div>
      </Panel>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type ModelModulePackage } from "@/services/fyApi";
import Panel from "@/shared/components/Panel/index.vue";

type Props = {
  packages: ModelModulePackage[];
  modelValue?: string[];
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  editable: false,
});

const { t } = useI18n();

const internalValue = ref<string[]>([]);

onMounted(() => {
  internalValue.value = [...(props.modelValue || [])];
});

const emit = defineEmits(["upate:modelValue"]);

watch(
  () => internalValue.value,
  () => {
    emit("upate:modelValue", internalValue.value);
  },
);

const activatePackage = (addonPackage: ModelModulePackage) => {
  if (!props.editable) {
    return;
  }

  internalValue.value = [...(props.modelValue || [])];

  addonPackage.modules.forEach((module) => {
    const additionalPackageModules = addonPackage.modules.filter(
      (packageModule) => packageModule.id === module.id,
    );
    const foundModules = internalValue.value.filter((id) => id === module.id);

    if (
      !foundModules.length ||
      foundModules.length < additionalPackageModules.length
    ) {
      internalValue.value.push(module.id);
    }
  });
};

const selectedPackage = (addonPackage: ModelModulePackage) => {
  return (
    JSON.stringify([...(props.modelValue || [])].sort()) ===
    JSON.stringify(addonPackage.modules.map((module) => module.id).sort())
  );
};
</script>

<script lang="ts">
export default {
  name: "AddonsModalPackages",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>

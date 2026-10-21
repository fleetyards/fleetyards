<script lang="ts">
export default {
  name: "BlueprintsTabs",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type BlueprintsTab,
  useBlueprintsTab,
} from "@/frontend/composables/useBlueprintsTab";

type Props = {
  tabs?: readonly BlueprintsTab[];
};

const props = withDefaults(defineProps<Props>(), {
  tabs: () => ["owned", "wanted"],
});

const { t } = useI18n();

const { activeTab } = useBlueprintsTab(props.tabs);
</script>

<!-- The wand is the hangar wishlist's own icon, so the tab matches the page
     it is the blueprint counterpart of. -->
<template>
  <BtnGroup segmented>
    <Btn
      :active="activeTab === 'owned'"
      mobile-icon-only
      data-test="blueprints-tab-owned"
      @click="activeTab = 'owned'"
    >
      <i class="fa-duotone fa-bookmark" />
      {{ t("labels.hangarBlueprints.owned") }}
    </Btn>
    <Btn
      :active="activeTab === 'wanted'"
      mobile-icon-only
      data-test="blueprints-tab-wanted"
      @click="activeTab = 'wanted'"
    >
      <i class="fa-duotone fa-wand-sparkles" />
      {{ t("labels.hangarBlueprints.wanted") }}
    </Btn>
    <Btn
      v-if="tabs.includes('missions')"
      :active="activeTab === 'missions'"
      mobile-icon-only
      data-test="blueprints-tab-missions"
      @click="activeTab = 'missions'"
    >
      <i class="fa-duotone fa-file-contract" />
      {{ t("labels.hangarBlueprints.missions") }}
    </Btn>
  </BtnGroup>
</template>

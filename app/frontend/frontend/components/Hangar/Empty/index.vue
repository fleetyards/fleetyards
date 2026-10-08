<script lang="ts">
export default {
  name: "VehiclesEmpty",
};
</script>

<script lang="ts" setup>
import Empty from "@/shared/components/Empty/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import HangarSyncBtn from "@/frontend/components/Hangar/SyncBtn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import SyncExtensionLinks from "@/frontend/components/SyncExtensionLinks/index.vue";
import { useHangarStore } from "@/frontend/stores/hangar";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import EmptyInfo from "@/shared/components/Empty/Info/index.vue";

type Props = {
  variant?: EmptyVariantsEnum;
  wishlist?: boolean;
};

withDefaults(defineProps<Props>(), {
  variant: EmptyVariantsEnum.DEFAULT,
  wishlist: false,
});

const { t } = useI18n();

const emit = defineEmits<{ openGuide: [] }>();

const hangarStore = useHangarStore();
</script>

<template>
  <Empty :variant="variant" :name="t('models.name')">
    <template #headline="{ queryPresent }">
      <span v-if="!queryPresent">
        <template v-if="wishlist">
          {{ t("empty.headlines.wishlist") }}
        </template>
        <template v-else>
          {{ t("empty.headlines.hangar") }}
        </template>
      </span>
    </template>
    <template v-if="!wishlist" #actions="{ queryPresent }">
      <HangarSyncBtn v-if="!queryPresent" />
      <Btn v-if="!queryPresent" @click="emit('openGuide')">
        {{ t("actions.empty.hangarGuide") }}
      </Btn>
    </template>
    <template #info="{ queryPresent }">
      <EmptyInfo v-if="queryPresent" :query-present="queryPresent" />
      <div v-else>
        <template v-if="wishlist">
          <p>
            {{ t("empty.info.wishlist") }}
          </p>
        </template>
        <template v-else>
          <p>
            {{ t("empty.info.hangar") }}
          </p>
          <div v-if="!hangarStore.extensionReady">
            <p>{{ t("empty.info.extension") }}</p>
            <SyncExtensionLinks />
          </div>
        </template>
      </div>
    </template>
  </Empty>
</template>

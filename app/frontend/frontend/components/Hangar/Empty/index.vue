<script lang="ts">
export default {
  name: "VehiclesEmpty",
};
</script>

<script lang="ts" setup>
import Empty from "@/shared/components/Empty/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import HangarSyncBtn from "@/frontend/components/Hangar/SyncBtn/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { extensionUrls } from "@/types/extension";
import { useHangarStore } from "@/frontend/stores/hangar";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";

type Props = {
  variant?: EmptyVariantsEnum;
  wishlist?: boolean;
};

withDefaults(defineProps<Props>(), {
  variant: EmptyVariantsEnum.DEFAULT,
  wishlist: false,
});

const { t } = useI18n();

const hangarStore = useHangarStore();

const comlink = useComlink();

const openGuide = () => {
  comlink.emit("open-modal", {
    wide: true,
    component: () =>
      import("@/frontend/components/Hangar/GuideModal/index.vue"),
  });
};
</script>

<template>
  <Empty :variant="variant" :name="t('models.name')">
    <template #headline="{ queryPresent }">
      <span v-if="!queryPresent">
        <template v-if="wishlist">
          {{ t("emptyBox.headlines.wishlist") }}
        </template>
        <template v-else>
          {{ t("emptyBox.headlines.hangar") }}
        </template>
      </span>
    </template>
    <template v-if="!wishlist" #actions>
      <HangarSyncBtn />
      <Btn @click="openGuide">
        {{ t("actions.empty.hangarGuide") }}
      </Btn>
    </template>
    <template #info="{ queryPresent }">
      <div v-if="queryPresent">
        <template v-if="wishlist">
          <p>
            {{ t("emptyBox.info.wishlist") }}
          </p>
        </template>
        <template v-else>
          <p>
            {{ t("emptyBox.info.hangar") }}
          </p>
          <div v-if="!hangarStore.extensionReady">
            <p>{{ t("emptyBox.info.extension") }}</p>
            <div class="sync-extension-platforms">
              <a
                v-for="link in extensionUrls"
                :key="`extension-link-${link.platform}`"
                v-tooltip="t(`labels.syncExtension.platforms.${link.platform}`)"
                :href="link.url"
                target="_blank"
              >
                <i :class="`fab fa-${link.platform}`" />
              </a>
            </div>
          </div>
        </template>
      </div>
    </template>
  </Empty>
</template>

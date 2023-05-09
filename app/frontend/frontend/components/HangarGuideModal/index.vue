<template>
  <Modal>
    <template #title>
      <h1>
        <template v-if="empty">
          {{ t("headlines.hangarGuideEmpty") }}
          <small class="text-muted">
            {{ t("sublines.hangarGuide.headline") }}
          </small>
        </template>
        <template v-else>
          {{ t("headlines.hangarGuide") }}
        </template>
      </h1>
    </template>

    <h2>{{ t("sublines.hangarGuide.add") }}</h2>
    <div class="hangar-guide-topic">
      <div>
        <p v-html="t('texts.hangarGuide.add')" />
        <div class="hangar-guide-highlight">
          {{ t("texts.hangarGuide.icon") }}
          <i class="fal fa-bookmark" />
        </div>
      </div>
      <img :src="images.add" class="hangar-guide-gif" alt="add-guide" />
    </div>
    <hr />
    <h2>{{ t("sublines.hangarGuide.edit") }}</h2>
    <div class="hangar-guide-topic">
      <div>
        <p v-html="t('texts.hangarGuide.edit')" />
        <div class="hangar-guide-highlight">
          {{ t("texts.hangarGuide.icon") }}
          <i class="fa fa-pencil" />
        </div>
      </div>
      <img :src="images.edit" class="hangar-guide-gif" alt="edit-guide" />
    </div>
    <hr />
    <h2>{{ t("sublines.hangarGuide.public") }}</h2>
    <div class="hangar-guide-topic">
      <p v-html="t('texts.hangarGuide.public')" />
      <img :src="images.public" class="hangar-guide-gif" alt="public-guide" />
    </div>
    <hr />
    <h2>{{ t("sublines.hangarGuide.fleetchart") }}</h2>
    <div class="hangar-guide-topic">
      <p v-html="t('texts.hangarGuide.fleetchart')" />
      <img
        :src="images.fleetchart"
        class="hangar-guide-gif"
        alt="fleetchart-guide"
      />
    </div>
    <hr />
    <h2>{{ t("sublines.hangarGuide.groups") }}</h2>
    <div class="hangar-guide-topic">
      <div>
        <p v-html="t('texts.hangarGuide.groups.add')" />
        <p v-html="t('texts.hangarGuide.groups.edit')" />
      </div>
      <img :src="images.groups" class="hangar-guide-gif" alt="groups-guide" />
    </div>
  </Modal>
</template>

<script lang="ts" setup>
import Modal from "@/frontend/core/components/AppModal/Inner/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import Store from "@/frontend/lib/Store";
import addImage from "@/images/hangar-guide/add.gif";
import editImage from "@/images/hangar-guide/edit.gif";
import publicImage from "@/images/hangar-guide/public.gif";
import fleetchartImage from "@/images/hangar-guide/fleetchart.gif";
import groupsImage from "@/images/hangar-guide/groups.gif";

const { t } = useI18n();

const empty = computed(() => Store.getters["hangar/empty"]);

const images = computed(() => ({
  add: addImage,
  edit: editImage,
  public: publicImage,
  fleetchart: fleetchartImage,
  groups: groupsImage,
}));
</script>

<script lang="ts">
export default {
  name: "HangarGuideModal",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>

<script lang="ts">
export default {
  name: "AnnouncementChannelFields",
};
</script>

<script lang="ts" setup>
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

/*
 * v-model per channel rather than one object: vee-validate's defineField hands
 * back a ref per field, and the pages bind them straight through.
 */
const notifyUsers = defineModel<boolean>("notifyUsers", { required: true });
const postDiscord = defineModel<boolean>("postDiscord", { required: true });
const postBluesky = defineModel<boolean>("postBluesky", { required: true });
const postX = defineModel<boolean>("postX", { required: true });

const { t } = useI18n();
</script>

<template>
  <FormToggle
    v-model="notifyUsers"
    name="notifyUsers"
    translation-key="announcement.notifyUsers"
    no-placeholder
    :info="t('labels.admin.announcements.notifyUsersInfo')"
    data-test="announcement-notify-users"
  />
  <FormToggle
    v-model="postDiscord"
    name="postDiscord"
    translation-key="announcement.postDiscord"
    no-placeholder
    data-test="announcement-post-discord"
  />
  <FormToggle
    v-model="postBluesky"
    name="postBluesky"
    translation-key="announcement.postBluesky"
    no-placeholder
    data-test="announcement-post-bluesky"
  />
  <FormToggle
    v-model="postX"
    name="postX"
    translation-key="announcement.postX"
    no-placeholder
    data-test="announcement-post-x"
  />
</template>

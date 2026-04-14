<script lang="ts">
export default {
  name: "SettingsProfilePage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useSessionStore } from "@/frontend/stores/session";
import { useForm } from "vee-validate";
import { useComlink } from "@/shared/composables/useComlink";
import { type UserUpdateInput } from "@/services/fyApi";
import { useUpdateProfile as useUpdateProfileMutation } from "@/services/fyApi";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const sessionStore = useSessionStore();

const initialValues = ref<UserUpdateInput>({
  avatar: undefined,
  rsiHandle: sessionStore.currentUser?.rsiHandle,
  location: sessionStore.currentUser?.location,
  currentSystem: sessionStore.currentUser?.currentSystem,
  homepage: sessionStore.currentUser?.homepage,
  discord: sessionStore.currentUser?.discord,
  youtube: sessionStore.currentUser?.youtube,
  twitch: sessionStore.currentUser?.twitch,
  guilded: sessionStore.currentUser?.guilded,
});

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
});

const [avatar, avatarProps] = defineField("avatar");
const [rsiHandle, rsiHandleProps] = defineField("rsiHandle");
const [location, locationProps] = defineField("location");
const [currentSystem, currentSystemProps] = defineField("currentSystem");
const [homepage, homepageProps] = defineField("homepage");
const [discord, discordProps] = defineField("discord");
const [youtube, youtubeProps] = defineField("youtube");
const [twitch, twitchProps] = defineField("twitch");
const [guilded, guildedProps] = defineField("guilded");

const submitting = ref(false);

watch(
  () => sessionStore.currentUser,
  () => {
    setupForm();
  },
);

onMounted(() => {
  if (sessionStore.currentUser) {
    setupForm();
  }
});

const setupForm = () => {
  rsiHandle.value = sessionStore.currentUser?.rsiHandle;
  location.value = sessionStore.currentUser?.location;
  currentSystem.value = sessionStore.currentUser?.currentSystem;
  homepage.value = sessionStore.currentUser?.homepage;
  discord.value = sessionStore.currentUser?.discord;
  youtube.value = sessionStore.currentUser?.youtube;
  twitch.value = sessionStore.currentUser?.twitch;
  guilded.value = sessionStore.currentUser?.guilded;
};

const comlink = useComlink();

const mutation = useUpdateProfileMutation();

const avatarFileInput = ref<InstanceType<typeof FormFileInput>>();

watch(avatar, async (newValue) => {
  if (!newValue) {
    return;
  }

  submitting.value = true;

  await mutation
    .mutateAsync({
      data: { avatar: newValue },
    })
    .then(() => {
      comlink.emit("user-update");
      avatar.value = undefined;
      displaySuccess({
        text: t("messages.updateProfile.success"),
      });
    })
    .catch((error) => {
      console.error(error);
      avatarFileInput.value?.clear();
      displayAlert({
        text: t("messages.updateProfile.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const { avatar: _avatar, ...rest } = values;

  await mutation
    .mutateAsync({
      data: rest,
    })
    .then(() => {
      comlink.emit("user-update");
      displaySuccess({
        text: t("messages.updateProfile.success"),
      });
    })
    .catch((error) => {
      console.error(error);
      displayAlert({
        text: t("messages.updateProfile.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'settings' }, label: t('nav.settings.index') }]"
  />

  <Heading hero>{{ t("headlines.settings.profile") }}</Heading>

  <form id="settings-profile-form" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-4">
        <FormFileInput
          ref="avatarFileInput"
          v-model="avatar"
          v-bind="avatarProps"
          :file="sessionStore.currentUser?.avatar"
          name="avatar"
          translation-key="user.avatar"
          :allowed-types="AllowedFileTypes.IMAGE"
          clearable
          avatar
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="rsiHandle"
          name="rsiHandle"
          v-bind="rsiHandleProps"
          icon="icon icon-rsi icon-label"
          translation-key="user.rsiHandle"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="location"
          name="location"
          v-bind="locationProps"
          icon="fa-duotone fa-location-dot"
          translation-key="user.location"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="currentSystem"
          name="currentSystem"
          v-bind="currentSystemProps"
          icon="fa-duotone fa-planet-ringed"
          translation-key="user.currentSystem"
        />
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="homepage"
          v-bind="homepageProps"
          name="homepage"
          translation-key="homepage"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="discord"
          v-bind="discordProps"
          name="discord"
          translation-key="discord"
          icon="fa-brands fa-discord"
        />
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="youtube"
          v-bind="youtubeProps"
          name="youtube"
          translation-key="youtube"
          icon="fa-brands fa-youtube"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="twitch"
          v-bind="twitchProps"
          name="twitch"
          translation-key="twitch"
          icon="fa-brands fa-twitch"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="guilded"
          v-bind="guildedProps"
          name="guilded"
          icon="fa-brands fa-guilded"
          :clearable="true"
          translation-key="guilded"
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      form-id="settings-profile-form"
      hide-cancel
    />
  </form>
</template>

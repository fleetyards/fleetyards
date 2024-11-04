<script lang="ts">
export default {
  name: "SettingsProfilePage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import AvatarUpload from "@/frontend/components/AvatarUpload/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { useForm } from "vee-validate";
import { useComlink } from "@/shared/composables/useComlink";
import { BtnTypesEnum, BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { type UserUpdateInput } from "@/services/fyApi";
import { useApiClient } from "@/frontend/composables/useApiClient";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useNoty();

const sessionStore = useSessionStore();

const initialValues = ref<UserUpdateInput>({
  rsiHandle: sessionStore.currentUser?.rsiHandle,
  homepage: sessionStore.currentUser?.homepage,
  discord: sessionStore.currentUser?.discord,
  youtube: sessionStore.currentUser?.youtube,
  twitch: sessionStore.currentUser?.twitch,
  guilded: sessionStore.currentUser?.guilded,
});

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
});

const [rsiHandle, rsiHandleProps] = defineField("rsiHandle");
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
  homepage.value = sessionStore.currentUser?.homepage;
  discord.value = sessionStore.currentUser?.discord;
  youtube.value = sessionStore.currentUser?.youtube;
  twitch.value = sessionStore.currentUser?.twitch;
  guilded.value = sessionStore.currentUser?.guilded;
};

const comlink = useComlink();

const { users: usersService } = useApiClient();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  try {
    await usersService.updateProfile({
      formData: values,
    });

    comlink.emit("user-update");
    displaySuccess({
      text: t("messages.updateProfile.success"),
    });
  } catch (error) {
    console.error(error);
    displayAlert({
      text: t("messages.updateProfile.failure"),
    });
  }

  submitting.value = false;
});
</script>

<template>
  <form @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-lg-12">
        <h1>{{ t("headlines.settings.profile") }}</h1>
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-6">
        <AvatarUpload />
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
          icon="fab fa-discord"
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
          icon="fab fa-youtube"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="twitch"
          v-bind="twitchProps"
          name="twitch"
          translation-key="twitch"
          icon="fab fa-twitch"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="guilded"
          v-bind="guildedProps"
          name="guilded"
          icon="fab fa-guilded"
          :clearable="true"
          translation-key="guilded"
        />
      </div>

      <div class="col-12">
        <br />
        <Btn
          :loading="submitting"
          :type="BtnTypesEnum.SUBMIT"
          :size="BtnSizesEnum.LARGE"
        >
          {{ t("actions.save") }}
        </Btn>
      </div>
    </div>
  </form>
</template>

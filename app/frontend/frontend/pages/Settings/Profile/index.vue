<template>
  <form @submit.prevent="submit">
    <div class="row">
      <div class="col-lg-12">
        <h1>{{ t("headlines.settings.profile") }}</h1>
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-6">
        <FormFileInput
          v-model="avatar"
          name="avatar"
          :extensions="fileExtensions"
          :accept="acceptedMimeTypes"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          id="rsiHandle"
          v-model="rsiHandle"
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
          name="homepage"
          translation-key="homepage"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="discord"
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
          name="youtube"
          translation-key="youtube"
          icon="fab fa-youtube"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="twitch"
          name="twitch"
          translation-key="twitch"
          icon="fab fa-twitch"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="guilded"
          name="guilded"
          icon="fab fa-guilded"
          :clearable="true"
          translation-key="guilded"
        />
      </div>

      <div class="col-12">
        <br />
        <Btn :loading="submitting" type="submit" size="large">
          {{ t("actions.save") }}
        </Btn>
      </div>
    </div>
  </form>
</template>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import FormFileInput from "@/frontend/core/components/Form/FormFileInput/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { useForm } from "vee-validate";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useNoty(t);

type UserUpdateInput = {
  rsiHandle?: string;
  homepage?: string;
  discord?: string;
  youtube?: string;
  twitch?: string;
  guilded?: string;
  avatar?: string;
  removeAvatar?: boolean;
};

const sessionStore = useSessionStore();

const initialValues = ref<UserUpdateInput>({
  rsiHandle: sessionStore.currentUser?.rsiHandle,
  homepage: sessionStore.currentUser?.homepage,
  discord: sessionStore.currentUser?.discord,
  youtube: sessionStore.currentUser?.youtube,
  twitch: sessionStore.currentUser?.twitch,
  guilded: sessionStore.currentUser?.guilded,
  avatar: sessionStore.currentUser?.avatar,
  removeAvatar: false,
});

const { useFieldModel, handleSubmit } = useForm({ initialValues });

const [
  rsiHandle,
  homepage,
  discord,
  youtube,
  twitch,
  guilded,
  avatar,
  removeAvatar,
] = useFieldModel([
  "rsiHandle",
  "homepage",
  "discord",
  "youtube",
  "twitch",
  "guilded",
  "avatar",
  "removeAvatar",
]);

const files = ref([]);

const fileExtensions = "jpg,jpeg,png,webp";

const acceptedMimeTypes = "image/png,image/jpeg,image/webp";

const submitting = ref(false);

const avatarUrl = computed(() => {
  return newAvatar.url || (currentUser.value && currentUser.value.avatar);
});

const newAvatar = computed(() => {
  return (files.value && files.value[0]) || {};
});

const fileExtensionsList = computed(() => {
  return fileExtensions.split(",");
});

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

const selectAvatar = () => {
  // form.removeAvatar = false;
  // $refs.upload.$el.querySelector("input").click();
};

watch(
  () => removeAvatar.value,
  () => {
    if (removeAvatar.value) {
      files.value = [];
    }
  },
);

const setupForm = () => {
  rsiHandle.value = sessionStore.currentUser?.rsiHandle;
  homepage.value = sessionStore.currentUser?.homepage;
  discord.value = sessionStore.currentUser?.discord;
  youtube.value = sessionStore.currentUser?.youtube;
  twitch.value = sessionStore.currentUser?.twitch;
  guilded.value = sessionStore.currentUser?.guilded;
  removeAvatar.value = false;
};

const submit = handleSubmit(async () => {
  submitting.value = true;

  const uploadResponse = await uploadAvatar();

  const response = await userCollection.updateProfile(this.form);

  submitting.value = false;

  if (!uploadResponse.error && !response.error) {
    comlink.emit("user-update");

    setTimeout(() => {
      files.value = [];
    }, 1000);

    displaySuccess({
      text: t("messages.updateProfile.success"),
    });
  }
});

const uploadAvatar = async () => {
  const uploadResponse = { error: null };

  if (newAvatar.value && newAvatar.value.file) {
    const uploadData = new FormData();
    uploadData.append("avatar", newAvatar.value.file);

    // uploadResponse = await this.$api.upload("users/current", uploadData);
  }

  return uploadResponse;
};

const updatedValue = (value) => {
  files.value = value;
};

const inputFilter = (newFile, oldFile, prevent) => {
  if (newFile && !oldFile) {
    if (
      !fileExtensionsList.some((extension) => newFile.name.endsWith(extension))
    ) {
      displayAlert({
        text: t("messages.avatarUpload.invalidExtension", {
          extensions: fileExtensions,
        }),
      });
      return prevent();
    }
  }
  if (newFile && (!oldFile || newFile.file !== oldFile.file)) {
    // eslint-disable-next-line no-param-reassign
    newFile.url = "";
    const URL = window.URL || window.webkitURL;
    if (URL && URL.createObjectURL) {
      // eslint-disable-next-line no-param-reassign
      newFile.url = URL.createObjectURL(newFile.file);
    }
  }

  return null;
};
</script>

<script lang="ts">
export default {
  name: "SettingsProfilePage",
};
</script>

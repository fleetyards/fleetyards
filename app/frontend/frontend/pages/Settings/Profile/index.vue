<template>
  <ValidationObserver v-if="form" v-slot="{ handleSubmit }" :slim="true">
    <form @submit.prevent="handleSubmit(submit)">
      <div class="row">
        <div class="col-lg-12">
          <h1>{{ $t("headlines.settings.profile") }}</h1>
        </div>
      </div>

      <div class="row">
        <div class="col-12 col-md-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="logo"
            :name="$t('labels.user.avatar')"
            :slim="true"
          >
            <div
              :class="{ 'has-error has-feedback': errors[0] }"
              class="form-group mb-3"
            >
              <VueUploadComponent
                ref="upload"
                :value="files"
                name="uploadAvatar"
                :extensions="fileExtensions"
                :accept="acceptedMimeTypes"
                class="avatar-uploader"
                @input="updatedValue"
                @input-filter="inputFilter"
              />
              <Avatar
                :avatar="avatarUrl"
                size="large"
                :editable="true"
                @upload="selectAvatar"
                @destroy="removeAvatar"
              />
            </div>
          </ValidationProvider>
        </div>
      </div>
      <div class="row">
        <div class="col-12 col-md-6">
          <FormInput
            id="rsiHandle"
            v-model="form.rsiHandle"
            icon="icon icon-rsi icon-label"
            translation-key="user.rsiHandle"
          />
        </div>
      </div>
      <hr />
      <div class="row">
        <div class="col-12 col-md-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="homepage"
            rules="url"
            :name="$t('labels.homepage')"
            :slim="true"
          >
            <FormInput
              id="homepage"
              v-model="form.homepage"
              translation-key="homepage"
              :error="errors[0]"
            />
          </ValidationProvider>
        </div>
        <div class="col-12 col-md-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="discord"
            rules="url"
            :name="$t('labels.discord')"
            :slim="true"
          >
            <FormInput
              id="discord"
              v-model="form.discord"
              translation-key="discord"
              icon="fab fa-discord"
              :error="errors[0]"
            />
          </ValidationProvider>
        </div>
      </div>
      <hr />
      <div class="row">
        <div class="col-12 col-md-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="youtube"
            rules="url"
            :name="$t('labels.youtube')"
            :slim="true"
          >
            <FormInput
              id="youtube"
              v-model="form.youtube"
              translation-key="youtube"
              icon="fab fa-youtube"
              :error="errors[0]"
            />
          </ValidationProvider>
        </div>
        <div class="col-12 col-md-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="twitch"
            rules="url"
            :name="$t('labels.twitch')"
            :slim="true"
          >
            <FormInput
              id="twitch"
              v-model="form.twitch"
              translation-key="twitch"
              icon="fab fa-twitch"
              :error="errors[0]"
            />
          </ValidationProvider>
        </div>
        <div class="col-12 col-md-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="guilded"
            rules="url"
            :name="$t('labels.guilded')"
            :slim="true"
          >
            <FormInput
              id="guilded"
              v-model="form.guilded"
              icon="fab fa-guilded"
              :clearable="true"
              translation-key="guilded"
              :error="errors[0]"
            />
          </ValidationProvider>
        </div>

        <div class="col-12">
          <br />
          <Btn :loading="submitting" type="submit" size="large">
            {{ $t("actions.save") }}
          </Btn>
        </div>
      </div>
    </form>
  </ValidationObserver>
</template>

<script lang="ts" setup>
import { ref, computed, watch } from "vue";
import { displaySuccess, displayAlert } from "@/frontend/lib/Noty";
import Btn from "@/frontend/core/components/Btn/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import VueUploadComponent from "vue-upload-component";
import userCollection from "@/frontend/api/collections/User";
import Avatar from "@/frontend/core/components/Avatar/index.vue";
import { useSessionStore } from "@/frontend/stores/Session";
import { useComlink } from "@/frontend/composables/useComlink";
import { useI18n } from "@/frontend/composables/useI18n";

interface UploadFile extends VUFile {
  url?: string;
}

const form = ref<Partial<UserForm>>({});

const files = ref<UploadFile[]>([]);

const fileExtensions = "jpg,jpeg,png,webp";

const acceptedMimeTypes = "image/png,image/jpeg,image/webp";

const submitting = ref(false);

const sessionStore = useSessionStore();

const avatarUrl = computed(
  () =>
    newAvatar.value.url ||
    (sessionStore.currentUser && sessionStore.currentUser.avatar)
);

const newAvatar = computed<UploadFile>(
  () => (files.value && files.value[0]) || {}
);

const fileExtensionsList = computed(() => fileExtensions.split(","));

watch(
  () => sessionStore.currentUser,
  () => {
    setupForm();
  },
  { deep: true }
);

const setupForm = () => {
  if (!sessionStore.currentUser) {
    return;
  }

  form.value = {
    rsiHandle: sessionStore.currentUser.rsiHandle,
    homepage: sessionStore.currentUser.homepage,
    discord: sessionStore.currentUser.discord,
    youtube: sessionStore.currentUser.youtube,
    twitch: sessionStore.currentUser.twitch,
    guilded: sessionStore.currentUser.guilded,
    removeAvatar: false,
  };
};

if (sessionStore.currentUser) {
  setupForm();
}

const upload = ref<InstanceType<typeof VueUploadComponent> | null>(null);

const selectAvatar = () => {
  form.value.removeAvatar = false;

  if (upload.value && upload.value.$el.querySelector("input")) {
    upload.value.$el.querySelector("input")?.click();
  }
};

const removeAvatar = () => {
  files.value = [];

  if (sessionStore.currentUser) {
    sessionStore.currentUser.avatar = undefined;
  }

  form.value.removeAvatar = true;
};

const comlink = useComlink();

const uploadAvatar = async () => {
  let uploadResponse: RecordResponse<User> = { error: null };

  if (newAvatar.value && newAvatar.value.file) {
    const uploadData = new FormData();
    uploadData.append("avatar", newAvatar.value.file);

    uploadResponse = await userCollection.uploadAvatar(uploadData);
  }

  return uploadResponse;
};

const { t } = useI18n();

const submit = async () => {
  submitting.value = true;

  const uploadResponse = await uploadAvatar();

  const response = await userCollection.updateProfile(form.value as UserForm);

  submitting.value = false;

  if (!uploadResponse.error && !response.error) {
    comlink.$emit("user-update");

    setTimeout(() => {
      files.value = [];
    }, 1000);

    displaySuccess({
      text: t("messages.updateProfile.success"),
    });
  }
};

const updatedValue = (value) => {
  files.value = value;
};

const inputFilter = (newFile, oldFile, prevent) => {
  if (newFile && !oldFile) {
    if (
      !fileExtensionsList.value.some((extension) =>
        newFile.name.endsWith(extension)
      )
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

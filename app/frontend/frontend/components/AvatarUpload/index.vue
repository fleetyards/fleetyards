<script lang="ts">
export default {
  name: "AvatarUpload",
};
</script>

<script lang="ts" setup>
import VueUploadComponent, { VueUploadItem } from "vue-upload-component";
import Avatar from "@/shared/components/Avatar/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import { useSessionStore } from "@/frontend/stores/session";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { UserUpdateInput } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useNoty();

const acceptedMimeTypes = "image/png,image/jpeg,image/webp";

const fileExtensions = "jpg,jpeg,png,webp";

const fileExtensionsList = computed(() => {
  return fileExtensions.split(",");
});

const files = ref<VueUploadItem[]>([]);

const inputFilter = (
  newFile: VueUploadItem,
  oldFile: VueUploadItem,
  prevent: () => void,
) => {
  if (newFile && !oldFile) {
    if (
      !fileExtensionsList.value.some((extension) =>
        newFile.name?.endsWith(extension),
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
    if (URL && URL.createObjectURL && newFile.file) {
      // eslint-disable-next-line no-param-reassign
      newFile.url = URL.createObjectURL(newFile.file);
    }
  }

  return null;
};

const { users: usersService } = useApiClient();

const comlink = useComlink();

const add = async () => {
  if (!newAvatar.value) {
    return;
  }

  const uploadData = new FormData();
  uploadData.append("avatar", newAvatar.value.file as Blob);

  try {
    await usersService.updateProfile({
      formData: uploadData as UserUpdateInput,
    });

    comlink.emit("user-update");

    displaySuccess({
      text: t("messages.avatarUpload.create.success"),
    });
  } catch (error) {
    console.error(error);

    displayAlert({
      text: t("messages.avatarUpload.create.failure"),
    });
  }
};

const remove = async () => {
  files.value = [];

  try {
    await usersService.updateProfile({
      formData: {
        removeAvatar: true,
      },
    });

    comlink.emit("user-update");

    displaySuccess({
      text: t("messages.avatarUpload.destroy.success"),
    });
  } catch (error) {
    console.error(error);

    displayAlert({
      text: t("messages.avatarUpload.destroy.failure"),
    });
  }
};

const sessionStore = useSessionStore();

const url = computed(() => {
  return newAvatar.value?.url || sessionStore.currentUser?.avatar;
});

const newAvatar = computed(() => {
  return (files.value && files.value[0]) as VueUploadItem | undefined;
});

const uploadComp = ref<InstanceType<typeof VueUploadComponent>>();

const selectAvatar = () => {
  uploadComp.value?.$el.querySelector("input").click();
};
</script>

<template>
  <div class="form-group mb-3">
    <VueUploadComponent
      ref="uploadComp"
      v-model="files"
      name="uploadAvatar"
      :extensions="fileExtensions"
      :accept="acceptedMimeTypes"
      class="avatar-uploader"
      @change="add"
      @input-filter="inputFilter"
    />
    <Avatar
      :avatar="url"
      size="large"
      :editable="true"
      @upload="selectAvatar"
      @destroy="remove"
    />
  </div>
</template>

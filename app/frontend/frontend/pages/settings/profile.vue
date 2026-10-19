<script lang="ts">
export default {
  name: "SettingsProfilePage",
};
</script>

<script lang="ts" setup>
import LocationInput from "@/shared/components/LocationInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import SupporterStatus from "@/shared/components/SupporterStatus/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useSessionStore } from "@/frontend/stores/session";
import { useForm } from "vee-validate";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type FilterOption,
  type UserUpdateInput,
  OmniauthProviderEnum,
  UserDateFormatEnum,
} from "@/services/fyApi";
import {
  RsiHandleVerifiedViaEnum,
  useDestroyMyRsiVerification,
  useUpdateProfile as useUpdateProfileMutation,
} from "@/services/fyApi";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import BtnConfirm from "@/shared/components/base/BtnConfirm/index.vue";
import OauthBtn from "@/shared/components/OauthBtn/index.vue";
import RsiHandleVerifiedBadge from "@/shared/components/RsiHandleVerifiedBadge/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInputGroup from "@/shared/components/base/FormInputGroup/index.vue";

const DISPLAY_NAME_LIMIT = 50;

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const sessionStore = useSessionStore();

const initialValues = ref<UserUpdateInput>({
  avatar: undefined,
  displayName: sessionStore.currentUser?.displayName,
  rsiHandle: sessionStore.currentUser?.rsiHandle,
  location: sessionStore.currentUser?.location,
  currentSystem: sessionStore.currentUser?.currentSystem,
  currentLocationId: sessionStore.currentUser?.currentLocation?.id ?? null,
  homepage: sessionStore.currentUser?.homepage,
  discord: sessionStore.currentUser?.discord,
  youtube: sessionStore.currentUser?.youtube,
  twitch: sessionStore.currentUser?.twitch,
  guilded: sessionStore.currentUser?.guilded,
  dateFormat:
    (sessionStore.currentUser?.dateFormat as UserDateFormatEnum) ??
    UserDateFormatEnum.DMY_DOTS,
});

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
});

const [avatar, avatarProps] = defineField("avatar");
const [displayName, displayNameProps] = defineField("displayName");
const [rsiHandle, rsiHandleProps] = defineField("rsiHandle");
const [location, locationProps] = defineField("location");
const [currentSystem] = defineField("currentSystem");
const [currentLocationId] = defineField("currentLocationId");
const [homepage, homepageProps] = defineField("homepage");
const [discord, discordProps] = defineField("discord");
const [youtube, youtubeProps] = defineField("youtube");
const [twitch, twitchProps] = defineField("twitch");
const [guilded, guildedProps] = defineField("guilded");
const [dateFormat, dateFormatProps] = defineField("dateFormat");

const dateFormatOptions = computed<FilterOption[]>(() =>
  Object.values(UserDateFormatEnum).map((value) => ({
    value,
    label: t(`labels.user.dateFormats.${value}`),
  })),
);

const submitting = ref(false);

const rsiHandleVerified = computed(
  () => sessionStore.currentUser?.rsiHandleVerified ?? false,
);

// The check reads the saved handle, so one still being typed has nothing to
// verify yet.
const canVerifyRsiHandle = computed(
  () => !!sessionStore.currentUser?.rsiHandle && !rsiHandleVerified.value,
);

const rsiHandleVerifiedViaCitizenid = computed(
  () =>
    rsiHandleVerified.value &&
    sessionStore.currentUser?.rsiHandleVerifiedVia ===
      RsiHandleVerifiedViaEnum.CITIZENID,
);

const revokeMutation = useDestroyMyRsiVerification();

const revokeRsiVerification = async () => {
  try {
    await revokeMutation.mutateAsync();
    comlink.emit("user-update");
  } catch (error) {
    displayAlert({ text: validationErrorFrom(error).message });
  }
};

const openRsiVerification = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/RsiHandleVerificationModal/index.vue"),
  });
};

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
  displayName.value = sessionStore.currentUser?.displayName;
  rsiHandle.value = sessionStore.currentUser?.rsiHandle;
  location.value = sessionStore.currentUser?.location;
  currentSystem.value = sessionStore.currentUser?.currentSystem;
  currentLocationId.value =
    sessionStore.currentUser?.currentLocation?.id ?? null;
  homepage.value = sessionStore.currentUser?.homepage;
  discord.value = sessionStore.currentUser?.discord;
  youtube.value = sessionStore.currentUser?.youtube;
  twitch.value = sessionStore.currentUser?.twitch;
  guilded.value = sessionStore.currentUser?.guilded;
  dateFormat.value =
    (sessionStore.currentUser?.dateFormat as UserDateFormatEnum) ??
    UserDateFormatEnum.DMY_DOTS;
};

const comlink = useComlink();

const mutation = useUpdateProfileMutation();

const avatarFileInput = ref<InstanceType<typeof FormFileInput>>();

watch(avatar, async (newValue) => {
  if (newValue === undefined) {
    return;
  }

  submitting.value = true;

  const data: Partial<UserUpdateInput> =
    newValue === null ? { removeAvatar: true } : { avatar: newValue };

  await mutation
    .mutateAsync({
      data,
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
      // Null rather than left out: a cleared name falls back to the username.
      data: { ...rest, displayName: rest.displayName || null },
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

  <SupporterStatus
    v-if="sessionStore.currentUser?.supporter"
    :supporter="sessionStore.currentUser?.supporter"
    :maintainer="sessionStore.currentUser?.maintainer"
    :supporter-tier="sessionStore.currentUser?.supporterTier"
    :supporter-recurring="sessionStore.currentUser?.supporterRecurring"
    :supporter-until="sessionStore.currentUser?.supporterUntil"
  />

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
      <div class="col-12 col-md-6">
        <FormInput
          v-model="displayName"
          v-bind="displayNameProps"
          name="displayName"
          translation-key="user.displayName"
          :placeholder="sessionStore.currentUser?.username"
          :info="t('labels.user.displayNameInfo')"
          :rules="`max:${DISPLAY_NAME_LIMIT}`"
          clearable
          data-test="settings-display-name"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInputGroup>
          <FormInput
            v-model="rsiHandle"
            name="rsiHandle"
            v-bind="rsiHandleProps"
            icon="icon icon-rsi icon-label"
            translation-key="user.rsiHandle"
            :disabled="rsiHandleVerified"
          >
            <template v-if="rsiHandleVerified" #suffix>
              <RsiHandleVerifiedBadge
                :verified-via="sessionStore.currentUser?.rsiHandleVerifiedVia"
                :citizenid-profile-url="
                  sessionStore.currentUser?.citizenidProfileUrl
                "
              />
            </template>
          </FormInput>
          <BtnConfirm
            v-if="rsiHandleVerified"
            :question="
              rsiHandleVerifiedViaCitizenid
                ? t('labels.user.rsiVerification.revokeCitizenidQuestion')
                : undefined
            "
            :size="BtnSizesEnum.SM"
            :disabled="revokeMutation.isPending.value"
            data-test="rsi-handle-revoke"
            @confirm="revokeRsiVerification"
          >
            {{ t("actions.user.rsiVerification.revoke") }}
          </BtnConfirm>
          <Btn
            v-if="canVerifyRsiHandle"
            :size="BtnSizesEnum.SM"
            data-test="rsi-handle-verify"
            @click="openRsiVerification"
          >
            {{ t("actions.user.rsiVerification.verify") }}
          </Btn>
          <OauthBtn
            v-if="!rsiHandleVerified"
            :provider="OmniauthProviderEnum.CITIZENID"
            :size="BtnSizesEnum.SM"
            inline
          >
            {{ t("actions.verifyWithCitizenId") }}
          </OauthBtn>
        </FormInputGroup>
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
        <LocationInput
          v-model="currentSystem"
          v-model:location-id="currentLocationId"
          :linked="sessionStore.currentUser?.currentLocation"
          name="currentSystem"
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
    <hr />
    <div class="row">
      <div class="col-12 col-md-6">
        <BaseSelect
          v-model="dateFormat"
          v-bind="dateFormatProps"
          :options="dateFormatOptions"
          :label="t('labels.user.dateFormat')"
          name="dateFormat"
          :searchable="false"
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

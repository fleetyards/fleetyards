<script lang="ts">
export default {
  name: "FleetSettingsPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useForm } from "vee-validate";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import {
  type Fleet,
  type FleetMember,
  type FleetUpdateInput,
  type ValidationError,
  useUpdateFleet as useUpdateFleetMutation,
  useDestroyFleet as useDestroyFleetMutation,
} from "@/services/fyApi";
import { type ErrorType } from "@/services/axiosClient";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const comlink = useComlink();

const router = useRouter();

const route = useRoute();

const updateMutation = useUpdateFleetMutation();

const destroyMutation = useDestroyFleetMutation();

const submitting = ref(false);

const deleting = ref(false);

const logoFile = computed(() => {
  if (!props.fleet.logo) {
    return undefined;
  }

  return {
    name: "logo",
    contentType: "image/png",
    size: 0,
    url: props.fleet.logo,
    smallUrl: props.fleet.logo,
  };
});

const initialValues = ref<FleetUpdateInput>({
  newLogo: undefined,
  fid: props.fleet.fid,
  name: props.fleet.name,
  description: props.fleet.description,
  rsiSid: props.fleet.rsiSid,
  discord: props.fleet.discord,
  ts: props.fleet.ts,
  homepage: props.fleet.homepage,
  twitch: props.fleet.twitch,
  youtube: props.fleet.youtube,
  guilded: props.fleet.guilded,
  publicFleet: props.fleet.publicFleet,
  publicFleetStats: props.fleet.publicFleetStats,
});

const validationSchema = {
  fid: "required|min:3|alpha_dash",
  name: "required|min:3|alpha_dash",
};

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
});

const [fid, fidProps] = defineField("fid");
const [name, nameProps] = defineField("name");
const [description, descriptionProps] = defineField("description");
const [rsiSid, rsiSidProps] = defineField("rsiSid");
const [discord, discordProps] = defineField("discord");
const [ts, tsProps] = defineField("ts");
const [homepage, homepageProps] = defineField("homepage");
const [twitch, twitchProps] = defineField("twitch");
const [youtube, youtubeProps] = defineField("youtube");
const [guilded, guildedProps] = defineField("guilded");
const [publicFleet, publicFleetProps] = defineField("publicFleet");
const [publicFleetStats, publicFleetStatsProps] =
  defineField("publicFleetStats");
const [newLogo, newLogoProps] = defineField("newLogo");

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({
      slug: route.params.slug as string,
      data: values,
    })
    .then(async (updatedFleet) => {
      displaySuccess({
        text: t("messages.fleet.update.success"),
      });

      comlink.emit("fleet-update");

      if (updatedFleet.slug !== route.params.slug) {
        await router.replace({
          name: "fleet-settings",
          params: { slug: updatedFleet.slug },
        });
      }
    })
    .catch((error) => {
      const response = error as unknown as ErrorType<ValidationError>;

      if (response.message) {
        displayAlert({
          text: response.message,
        });
      } else {
        displayAlert({
          text: t("messages.fleet.update.failure"),
        });
      }
    })
    .finally(() => {
      submitting.value = false;
    });
});

const onDestroy = async () => {
  deleting.value = true;

  displayConfirm({
    text: t("messages.confirm.fleet.destroy"),
    onConfirm: async () => {
      await destroyMutation
        .mutateAsync({
          slug: route.params.slug as string,
        })
        .then(async () => {
          comlink.emit("fleet-update");

          displaySuccess({
            text: t("messages.fleet.destroy.success"),
          });

          await router.push({ name: "home" }).catch(() => {});
        })
        .catch(() => {
          displayAlert({
            text: t("messages.fleet.destroy.failure"),
          });
        })
        .finally(() => {
          deleting.value = false;
        });
    },
    onClose: () => {
      deleting.value = false;
    },
  });
};
</script>

<template>
  <form @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="newLogo"
          v-bind="newLogoProps"
          :file="logoFile"
          name="newLogo"
          translation-key="fleet.logo"
          :allowed-types="AllowedFileTypes.IMAGE"
          clearable
          avatar
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="fid"
          name="fid"
          :rules="validationSchema.fid"
          :label="t('labels.fleet.fid')"
          v-bind="fidProps"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="name"
          name="name"
          :rules="validationSchema.name"
          v-bind="nameProps"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <FormTextarea
          v-model="description"
          name="description"
          v-bind="descriptionProps"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="rsiSid"
          name="rsiSid"
          icon="icon icon-rsi icon-label"
          translation-key="fleet.rsiSid"
          v-bind="rsiSidProps"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormCheckbox
          v-model="publicFleet"
          name="publicFLeet"
          translation-key="fleet.public"
          v-bind="publicFleetProps"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormCheckbox
          v-model="publicFleetStats"
          name="publicFleetStats"
          translation-key="fleet.publicStats"
          v-bind="publicFleetStatsProps"
        />
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput v-model="homepage" name="homepage" v-bind="homepageProps" />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="ts"
          name="ts"
          icon="fab fa-teamspeak"
          translation-key="fleet.ts"
          v-bind="tsProps"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="discord"
          name="discord"
          icon="fab fa-discord"
          v-bind="discordProps"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="guilded"
          name="guilded"
          icon="fab fa-guilded"
          v-bind="guildedProps"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="twitch"
          name="twitch"
          icon="fab fa-twitch"
          v-bind="twitchProps"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="youtube"
          name="youtube"
          icon="fab fa-youtube"
          v-bind="youtubeProps"
        />
      </div>
    </div>
    <hr />
    <Btn
      :loading="submitting"
      type="submit"
      size="large"
      data-test="fleet-save"
    >
      {{ t("actions.save") }}
    </Btn>
    <Btn
      :loading="deleting"
      size="large"
      variant="danger"
      data-test="fleet-delete"
      @click="onDestroy"
    >
      {{ t("actions.delete") }}
    </Btn>
  </form>
</template>

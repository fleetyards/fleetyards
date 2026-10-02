<script lang="ts">
export default {
  name: "FleetSettingsPage",
};
</script>

<script lang="ts" setup>
import LocationInput from "@/shared/components/LocationInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useForm } from "vee-validate";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum, BtnTonesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormMarkdownEditor from "@/shared/components/base/FormMarkdownEditor/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import {
  FeatureFlagName,
  type Fleet,
  type FleetMember,
  type FleetUpdateInput,
  useUpdateFleet as useUpdateFleetMutation,
  useDestroyFleet as useDestroyFleetMutation,
} from "@/services/fyApi";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { narrowerAudienceDisabled } from "@/frontend/utils/audienceToggles";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useFleetProfileLabels } from "@/frontend/composables/useFleetProfileLabels";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

// What the API accepts. The field draws it as a running count rather than
// leaving a long description to be turned down on save.
const DESCRIPTION_MAX = 10_000;

const { t } = useI18n();

const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

const comlink = useComlink();

const router = useRouter();

const route = useRoute();

const updateMutation = useUpdateFleetMutation();

const destroyMutation = useDestroyFleetMutation();

const submitting = ref(false);

const deleting = ref(false);

const initialValues = ref<FleetUpdateInput>({
  logo: undefined,
  name: props.fleet.name,
  description: props.fleet.description,
  discord: props.fleet.discord,
  ts: props.fleet.ts,
  homepage: props.fleet.homepage,
  headquarters: props.fleet.headquarters ?? "",
  headquartersLocationId: props.fleet.headquartersLocation?.id ?? null,
  twitch: props.fleet.twitch,
  youtube: props.fleet.youtube,
  guilded: props.fleet.guilded,
  publicFleet: props.fleet.publicFleet,
  publicFleetStats: props.fleet.publicFleetStats,
  alliesFleet: props.fleet.alliesFleet,
  alliesFleetStats: props.fleet.alliesFleetStats,
  alliesFleetMembers: props.fleet.alliesFleetMembers,
  // A fleet that never chose follows publicFleet, so that is what it shows.
  listed: props.fleet.listed ?? props.fleet.publicFleet,
  alignment: props.fleet.alignment,
});

const validationSchema = {
  name: "required|min:3|fleetName",
  description: `max:${DESCRIPTION_MAX}`,
};

const { defineField, handleSubmit, meta, resetForm, setErrors } = useForm({
  initialValues: initialValues.value,
});

const [name, nameProps] = defineField("name");
const [description, descriptionProps] = defineField("description");
const [discord, discordProps] = defineField("discord");
const [ts, tsProps] = defineField("ts");
const [homepage, homepageProps] = defineField("homepage");
const [headquarters] = defineField("headquarters");
const [headquartersLocationId] = defineField("headquartersLocationId");
const [twitch, twitchProps] = defineField("twitch");
const [youtube, youtubeProps] = defineField("youtube");
const [guilded, guildedProps] = defineField("guilded");
const [publicFleet, publicFleetProps] = defineField("publicFleet");
const [publicFleetStats, publicFleetStatsProps] =
  defineField("publicFleetStats");
const [alliesFleet, alliesFleetProps] = defineField("alliesFleet");
const [alliesFleetStats, alliesFleetStatsProps] =
  defineField("alliesFleetStats");
const [alliesFleetMembers, alliesFleetMembersProps] =
  defineField("alliesFleetMembers");
const [logo, logoProps] = defineField("logo");
const [listed, listedProps] = defineField("listed");
const [alignment, alignmentProps] = defineField("alignment");

// See `narrowerAudienceDisabled`. The roster has no public form at all, which
// is why the third toggle is never passed one.
const alliesDisabled = (isPublic: unknown) =>
  narrowerAudienceDisabled(isPublic, submitting.value);

const { isFleetFeatureEnabled } = useFeatures();

const { activityLabel, commitmentLabel, languageLabel, alignmentOptions } =
  useFleetProfileLabels();

// Only a verified fleet can be listed, and the directory has to be rolled out
// for the choice to mean anything.
const directoryAvailable = computed(
  () =>
    props.fleet.rsiVerified &&
    isFleetFeatureEnabled(props.fleet, FeatureFlagName.FLEET_DIRECTORY),
);

const canManage = computed(
  () => props.membership.capabilities?.manageFleet ?? false,
);

const rsiProfile = computed(() =>
  [
    {
      key: "primaryActivity",
      value: activityLabel(props.fleet.primaryActivity),
    },
    {
      key: "secondaryActivity",
      value: activityLabel(props.fleet.secondaryActivity),
    },
    { key: "language", value: languageLabel(props.fleet.language) },
    { key: "commitment", value: commitmentLabel(props.fleet.commitment) },
    { key: "recruiting", value: yesNo(props.fleet.recruiting) },
    { key: "roleplay", value: yesNo(props.fleet.roleplay) },
  ].map((item) => ({ ...item, value: item.value ?? "-" })),
);

function yesNo(value?: boolean | null) {
  if (value === null || value === undefined) return undefined;

  return t(value ? "labels.true" : "labels.false");
}

// A fleet that never chose follows publicFleet, so until a manager touches the
// toggle it shows exactly that -- live, as publicFleet is switched -- and the
// save leaves it out. Sending what it showed would turn a choice nobody made
// into an explicit one, which would stop it following publicFleet.
const listedChosen = ref(
  props.fleet.listed !== null && props.fleet.listed !== undefined,
);

const chooseListed = (value: boolean) => {
  listedChosen.value = true;
  listed.value = value;
};

watch(publicFleet, (isPublic) => {
  if (!listedChosen.value) listed.value = !!isPublic;
});

const payloadFrom = (values: FleetUpdateInput): FleetUpdateInput => {
  if (listedChosen.value) return values;

  const { listed: _listed, ...rest } = values;

  return rest;
};

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({
      slug: route.params.slug as string,
      data: payloadFrom(values),
    })
    .then(() => {
      displaySuccess({
        text: t("messages.fleet.update.success"),
      });

      comlink.emit("fleet-update");
    })
    .catch((error) => {
      const { message, formErrors } = validationErrorFrom(error);

      setErrors(formErrors);

      displayAlert({
        text: message || t("messages.fleet.update.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = () => {
  resetForm();
};

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
  <form id="fleet-settings-form" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="logo"
          v-bind="logoProps"
          :file="fleet.logo"
          name="logo"
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
          v-model="name"
          name="name"
          :rules="validationSchema.name"
          v-bind="nameProps"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <FormMarkdownEditor
          v-model="description"
          name="description"
          v-bind="descriptionProps"
          :rules="validationSchema.description"
          :maxlength="DESCRIPTION_MAX"
        />
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="publicFleet"
          name="publicFleet"
          translation-key="fleet.public"
          v-bind="publicFleetProps"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="publicFleetStats"
          name="publicFleetStats"
          translation-key="fleet.publicStats"
          v-bind="publicFleetStatsProps"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="alliesFleet"
          name="alliesFleet"
          translation-key="fleet.allies"
          v-bind="alliesFleetProps"
          :disabled="alliesDisabled(publicFleet)"
          :implied="!!publicFleet"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="alliesFleetStats"
          name="alliesFleetStats"
          translation-key="fleet.alliesStats"
          v-bind="alliesFleetStatsProps"
          :disabled="alliesDisabled(publicFleetStats)"
          :implied="!!publicFleetStats"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="alliesFleetMembers"
          name="alliesFleetMembers"
          translation-key="fleet.alliesMembers"
          v-bind="alliesFleetMembersProps"
          :disabled="submitting"
        />
      </div>
    </div>
    <template v-if="directoryAvailable">
      <hr />
      <div class="row" data-test="fleet-directory-settings">
        <div v-if="canManage" class="col-12 col-md-6">
          <FormToggle
            :model-value="listed"
            name="listed"
            translation-key="fleet.listed"
            :info="t('labels.fleet.listedInfo')"
            v-bind="listedProps"
            :disabled="submitting || !publicFleet"
            @update:model-value="chooseListed"
          />
        </div>
        <div class="col-12 col-md-6">
          <BaseSelect
            v-model="alignment"
            v-bind="alignmentProps"
            :options="alignmentOptions"
            :label="t('labels.fleet.alignment')"
            name="alignment"
            :searchable="false"
            unsorted
            nullable
          />
        </div>
      </div>
      <div class="row">
        <div class="col-12 col-md-6">
          <p class="text-muted">{{ t("labels.fleet.rsiProfile.info") }}</p>
          <div class="metrics-card__rows" data-test="fleet-rsi-profile">
            <div
              v-for="item in rsiProfile"
              :key="item.key"
              class="metrics-card__row"
            >
              <div class="metrics-card__row__label">
                {{ t(`labels.fleet.rsiProfile.${item.key}`) }}
              </div>
              <div class="metrics-card__row__value">{{ item.value }}</div>
            </div>
          </div>
        </div>
      </div>
    </template>
    <hr />
    <div class="row">
      <div class="col-12 col-md-6">
        <LocationInput
          v-model="headquarters"
          v-model:location-id="headquartersLocationId"
          :linked="fleet.headquartersLocation"
          name="headquarters"
          translation-key="fleet.headquarters"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput v-model="homepage" name="homepage" v-bind="homepageProps" />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="ts"
          name="ts"
          icon="fa-brands fa-teamspeak"
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
          icon="fa-brands fa-discord"
          v-bind="discordProps"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="guilded"
          name="guilded"
          icon="fa-brands fa-guilded"
          v-bind="guildedProps"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="twitch"
          name="twitch"
          icon="fa-brands fa-twitch"
          v-bind="twitchProps"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="youtube"
          name="youtube"
          icon="fa-brands fa-youtube"
          v-bind="youtubeProps"
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      form-id="fleet-settings-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>

  <hr />

  <div class="row">
    <div class="col-12">
      <br />
      <p>
        {{ t("labels.fleet.destroyInfo") }}
      </p>
      <div class="text-center">
        <Btn
          :loading="deleting"
          data-test="fleet-delete"
          @click="onDestroy"
          :size="BtnSizesEnum.LG"
          :tone="BtnTonesEnum.DANGER"
        >
          {{ t("actions.destroyFleet") }}
        </Btn>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";
</style>

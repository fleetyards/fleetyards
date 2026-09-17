<script lang="ts">
export default {
  name: "AdminAnnouncementEditPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import {
  type Announcement,
  type AnnouncementInput,
  AnnouncementInputStatusEnum,
  AnnouncementStatusEnum,
  useUpdateAnnouncement,
  getAnnouncementsQueryKey,
  getAnnouncementQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import AnnouncementChannelFields from "@/admin/components/Announcements/ChannelFields/index.vue";
import AnnouncementPartsEditor from "@/admin/components/Announcements/PartsEditor/index.vue";
import AnnouncementDeliveries from "@/admin/components/Announcements/Deliveries/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  announcement: Announcement;
};

const props = defineProps<Props>();

const { t, l } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

type FormValues = {
  title: string;
  body: string;
  link?: string;
  publishAt?: string;
  notifyUsers: boolean;
  postDiscord: boolean;
  postBluesky: boolean;
  postX: boolean;
};

const schedule = ref(
  props.announcement.status === AnnouncementStatusEnum.SCHEDULED,
);

// publishAt is required only once scheduling is on. Without the rule the form
// submits an empty date and the API answers with the model's own validation
// error -- a round trip to say what the field could have said itself.
const validationSchema = computed(() => ({
  title: "required",
  body: "required",
  ...(schedule.value ? { publishAt: "required" } : {}),
}));

const { defineField, handleSubmit, meta, values } = useForm<FormValues>({
  initialValues: {
    title: props.announcement.title,
    body: props.announcement.body,
    link: props.announcement.link,
    publishAt: props.announcement.publishAt,
    notifyUsers: props.announcement.notifyUsers,
    postDiscord: props.announcement.postDiscord,
    postBluesky: props.announcement.postBluesky,
    postX: props.announcement.postX,
  },
  validationSchema,
});

const [title, titleProps] = defineField("title");
const [body, bodyProps] = defineField("body");
const [link, linkProps] = defineField("link");
const [publishAt, publishAtProps] = defineField("publishAt");
const [notifyUsers] = defineField("notifyUsers");
const [postDiscord] = defineField("postDiscord");
const [postBluesky] = defineField("postBluesky");
const [postX] = defineField("postX");

const noChannel = computed(
  () =>
    !values.notifyUsers &&
    !values.postDiscord &&
    !values.postBluesky &&
    !values.postX,
);

// The schedule switch is not a form field, so meta.dirty does not see it.
const scheduledInitially =
  props.announcement.status === AnnouncementStatusEnum.SCHEDULED;
const scheduleDirty = computed(() => schedule.value !== scheduledInitially);

const discordParts = ref<string[]>([...props.announcement.discordParts]);
const socialParts = ref<string[]>([...props.announcement.socialParts]);

const partsDirty = computed(
  () =>
    JSON.stringify(discordParts.value) !==
      JSON.stringify(props.announcement.discordParts) ||
    JSON.stringify(socialParts.value) !==
      JSON.stringify(props.announcement.socialParts),
);

const submitting = ref(false);

const updateMutation = useUpdateAnnouncement({
  mutation: {
    onSettled: () => {
      void Promise.all([
        queryClient.invalidateQueries({ queryKey: getAnnouncementsQueryKey() }),
        queryClient.invalidateQueries({
          queryKey: getAnnouncementQueryKey(props.announcement.id),
        }),
      ]);
    },
  },
});

const onSubmit = handleSubmit(async (formValues) => {
  if (noChannel.value) {
    displayAlert({ text: t("labels.admin.announcements.noChannel") });
    return;
  }

  submitting.value = true;

  const payload: AnnouncementInput = {
    title: formValues.title,
    body: formValues.body,
    discordParts: discordParts.value,
    socialParts: socialParts.value,
    link: formValues.link || undefined,
    status: schedule.value
      ? AnnouncementInputStatusEnum.SCHEDULED
      : AnnouncementInputStatusEnum.DRAFT,
    // FormDateTime hands back local time, and the schema wants RFC 3339.
    publishAt:
      schedule.value && formValues.publishAt
        ? new Date(formValues.publishAt).toISOString()
        : undefined,
    notifyUsers: formValues.notifyUsers,
    postDiscord: formValues.postDiscord,
    postBluesky: formValues.postBluesky,
    postX: formValues.postX,
  };

  await updateMutation
    .mutateAsync({ id: props.announcement.id, data: payload })
    .then(() => {
      displaySuccess({ text: t("messages.announcement.updated") });
    })
    .catch((error) => {
      console.error("Error updating announcement:", error);
      displayAlert({ text: t("messages.announcement.updateFailed") });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(
    extend({
      name: "admin-announcements",
      hash: `#${props.announcement.id}`,
    }),
  );
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      {
        to: { name: 'admin-announcements' },
        label: t('headlines.admin.announcements.index'),
      },
    ]"
  />
  <Heading hero>{{ t("headlines.admin.announcements.edit") }}</Heading>
  <form id="admin-announcement-edit-form" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-7">
        <FormInput
          v-model="title"
          v-bind="titleProps"
          translation-key="announcement.title"
          name="title"
        />
        <FormTextarea
          v-model="body"
          v-bind="bodyProps"
          translation-key="announcement.body"
          name="body"
        />
        <FormInput
          v-model="link"
          v-bind="linkProps"
          translation-key="announcement.link"
          name="link"
        />

        <hr />

        <AnnouncementPartsEditor
          v-model="discordParts"
          name="discord-parts"
          :label="t('labels.announcement.discordParts')"
          :hint="t('labels.admin.announcements.discordPartsInfo')"
          :part-placeholder="t('placeholders.announcement.discordPart')"
          :limits="[{ label: 'Discord', limit: 2000, counter: 'discord' }]"
        />

        <hr />

        <AnnouncementPartsEditor
          v-model="socialParts"
          name="social-parts"
          :label="t('labels.announcement.socialParts')"
          :hint="t('labels.admin.announcements.socialPartsInfo')"
          :part-placeholder="t('placeholders.announcement.socialPart')"
          :limits="[
            { label: 'X', limit: 280, counter: 'x' },
            { label: 'Bluesky', limit: 300, counter: 'bluesky' },
          ]"
        />
      </div>
      <div class="col-12 col-md-5">
        <AnnouncementChannelFields
          v-model:notify-users="notifyUsers"
          v-model:post-discord="postDiscord"
          v-model:post-bluesky="postBluesky"
          v-model:post-x="postX"
        />
        <p v-if="noChannel" class="announcement-form__warning">
          {{ t("labels.admin.announcements.noChannel") }}
        </p>
        <p
          v-else-if="props.announcement.lastTestedAt"
          class="announcement-form__hint"
        >
          {{
            t("labels.admin.announcements.lastTested", {
              time: l(
                props.announcement.lastTestedAt,
                "datetime.formats.short",
              ),
            })
          }}
        </p>
        <hr />

        <FormToggle
          v-model="schedule"
          name="schedule"
          translation-key="announcement.schedule"
          no-placeholder
        />
        <FormDateTime
          v-if="schedule"
          v-model="publishAt"
          v-bind="publishAtProps"
          translation-key="announcement.publishAt"
          name="publishAt"
        />

        <hr />

        <Panel v-if="props.announcement.deliveries.length">
          <PanelHeading>
            {{ t("headlines.admin.announcements.deliveries") }}
          </PanelHeading>
          <PanelBody>
            <AnnouncementDeliveries :announcement="props.announcement" />
          </PanelBody>
        </Panel>
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      form-id="admin-announcement-edit-form"
      :dirty="meta.dirty || meta.touched || scheduleDirty || partsDirty"
      @cancel="handleCancel"
    />
  </form>
</template>

<style lang="scss" scoped>
.announcement-form__warning {
  color: $danger;
  margin: 0 0 16px;
}

.announcement-form__hint {
  color: $gray-lighter;
  margin: 0 0 16px;
}
</style>

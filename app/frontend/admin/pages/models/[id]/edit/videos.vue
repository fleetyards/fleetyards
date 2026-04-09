<script lang="ts">
export default {
  name: "AdminModelEditVideosPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import {
  type ModelExtended,
  type Video,
  type VideoInput,
  type FilterOption,
  VideoTypeEnum,
  useVideos as useVideosQuery,
  useCreateVideo as useCreateVideoMutation,
  useUpdateVideo as useUpdateVideoMutation,
  useDestroyVideo as useDestroyVideoMutation,
  getVideosQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();
const queryClient = useQueryClient();

const editableList = ref<{
  editingId: string | null;
  creating: boolean;
  startCreate: () => void;
  finishEdit: () => void;
  finishCreate: () => void;
} | null>(null);

const videosQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    modelIdEq: props.model.id,
  },
}));

const videosQueryKey = computed(() =>
  getVideosQueryKey(videosQueryParams.value),
);

const { perPage, page, updatePerPage } = usePagination(videosQueryKey);

const { data, isLoading } = useVideosQuery(videosQueryParams);

const invalidateVideos = () =>
  queryClient.invalidateQueries({
    queryKey: getVideosQueryKey(),
  });

// Edit
const editForm = ref<VideoInput>({});

const onStartEdit = (record: Video) => {
  editForm.value = {
    url: record.url,
    videoType: record.type,
  };
};

const updateMutation = useUpdateVideoMutation({
  mutation: {
    onSettled: invalidateVideos,
  },
});

const onSaveEdit = async () => {
  const id = editableList.value?.editingId;
  if (!id) return;

  await updateMutation.mutateAsync({
    id,
    data: editForm.value,
  });

  editableList.value?.finishEdit();
};

// Delete
const destroyMutation = useDestroyVideoMutation({
  mutation: {
    onSettled: invalidateVideos,
  },
});

const onDestroy = async (record: Video) => {
  await destroyMutation.mutateAsync({ id: record.id });
};

// Create
const createForm = ref<VideoInput>({
  modelId: props.model.id,
  videoType: VideoTypeEnum.YOUTUBE,
});

const onStartCreate = () => {
  createForm.value = {
    modelId: props.model.id,
    videoType: VideoTypeEnum.YOUTUBE,
  };
};

const createMutation = useCreateVideoMutation({
  mutation: {
    onSettled: invalidateVideos,
  },
});

const onSaveCreate = async () => {
  await createMutation.mutateAsync({
    data: createForm.value,
  });

  editableList.value?.finishCreate();
};

// Helpers
const videoTypeIcons: Record<string, string> = {
  [VideoTypeEnum.YOUTUBE]: "fa-brands fa-youtube",
};

const thumbnailUrl = (video: Video) => {
  if (video.type === VideoTypeEnum.YOUTUBE && video.videoId) {
    return `https://img.youtube.com/vi/${video.videoId}/mqdefault.jpg`;
  }
  return undefined;
};

// Dropdown options
const videoTypeOptions: FilterOption[] = Object.values(VideoTypeEnum).map(
  (value) => ({
    label: value,
    value,
  }),
);
</script>

<template>
  <div class="flex items-center justify-between">
    <Heading hero>{{ t("headlines.admin.models.edit.videos") }}</Heading>
    <Btn
      :size="BtnSizesEnum.SMALL"
      :disabled="editableList?.creating"
      @click="editableList?.startCreate()"
    >
      <i class="fa-duotone fa-plus" />
      {{ t("actions.add") }}
    </Btn>
  </div>

  <InlineEditableList
    empty-name="Videos"
    :loading="isLoading"
    ref="editableList"
    :items="(data?.items as Video[]) || []"
    :confirm-destroy-text="t('messages.confirm.video.destroy')"
    @start-edit="onStartEdit"
    @save-edit="onSaveEdit"
    @start-create="onStartCreate"
    @save-create="onSaveCreate"
    @destroy="onDestroy"
  >
    <template #display="{ item }">
      <LazyImage
        v-if="thumbnailUrl(item)"
        :src="thumbnailUrl(item)"
        :variant="LazyImageVariantsEnum.WIDE_SMALL"
        :alt="item.url"
        class="video-thumbnail"
      />
      <i :class="videoTypeIcons[item.type]" class="video-type-icon" />
      <a :href="item.url" target="_blank">{{ item.url }}</a>
    </template>

    <template #edit>
      <FilterGroup
        v-model="editForm.videoType"
        name="edit-video-type"
        :options="videoTypeOptions"
        :nullable="false"
        label="Type"
      />
      <FormInput
        v-model="editForm.url"
        name="edit-url"
        translation-key="video.url"
      />
    </template>

    <template #create>
      <FilterGroup
        v-model="createForm.videoType"
        name="create-video-type"
        :options="videoTypeOptions"
        :nullable="false"
        label="Type"
      />
      <FormInput
        v-model="createForm.url"
        name="create-url"
        translation-key="video.url"
      />
    </template>
  </InlineEditableList>

  <Paginator
    v-if="data"
    :query-result-ref="data"
    :per-page="perPage"
    :update-per-page="updatePerPage"
  />
</template>

<style lang="scss" scoped>
.video-thumbnail {
  width: 80px;
  flex-shrink: 0;
}

.video-type-icon {
  font-size: 1.2rem;
  opacity: 0.7;
}
</style>

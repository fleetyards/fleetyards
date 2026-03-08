<script lang="ts">
export default {
  name: "AdminModelImagesPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import {
  type ModelExtended,
  type Image,
  type ImageInput,
  GalleryTypeEnum,
  useImages as useImagesQuery,
  useCreateImage as useCreateImageMutation,
  useUpdateImage as useUpdateImageMutation,
  useDestroyImage as useDestroyImageMutation,
  getImagesQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import DirectUpload, {
  type FileUpload,
} from "@/shared/components/DirectUpload/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();
const queryClient = useQueryClient();

const editableList = ref<{
  editingId: string | null;
  finishEdit: () => void;
} | null>(null);

const imagesQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    galleryIdEq: props.model.id,
    galleryTypeEq: GalleryTypeEnum.MODEL,
  },
}));

const imagesQueryKey = computed(() =>
  getImagesQueryKey(imagesQueryParams.value),
);

const { perPage, page, updatePerPage } = usePagination(imagesQueryKey);

const { data, isLoading } = useImagesQuery(imagesQueryParams);

const invalidateImages = async () => {
  await queryClient.invalidateQueries({
    queryKey: getImagesQueryKey(),
  });
};

// Edit
const editForm = ref<ImageInput>({});

const onStartEdit = (record: Image) => {
  editForm.value = {
    caption: record.caption,
  };
};

const updateMutation = useUpdateImageMutation({
  mutation: {
    onSettled: invalidateImages,
  },
});

const toggleField = async (
  item: Image,
  field: "enabled" | "global" | "background",
) => {
  await updateMutation.mutateAsync({
    id: item.id,
    data: { [field]: !item[field] },
  });
};

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
const destroyMutation = useDestroyImageMutation({
  mutation: {
    onSettled: invalidateImages,
  },
});

const onDestroy = async (record: Image) => {
  await destroyMutation.mutateAsync({ id: record.id });
};

// Direct Upload
const uploadMutation = useCreateImageMutation({
  mutation: {
    onSettled: invalidateImages,
  },
});

const handleUploadDone = async (files: FileUpload[]) => {
  const blobIds = files
    .map((file) => file.blob?.signed_id)
    .filter((id): id is string => !!id);

  for (const blobId of blobIds) {
    await uploadMutation.mutateAsync({
      data: {
        galleryId: props.model.id,
        galleryType: GalleryTypeEnum.MODEL,
        file: blobId,
      },
    });
  }

  await invalidateImages();
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.models.images") }}</Heading>

  <DirectUpload
    direct-upload
    multiple
    inline
    hide-finished
    @upload:done="handleUploadDone"
  />

  <InlineEditableList
    empty-name="Images"
    :loading="isLoading"
    ref="editableList"
    :items="(data?.items as Image[]) || []"
    :confirm-destroy-text="t('messages.confirm.image.destroy')"
    @start-edit="onStartEdit"
    @save-edit="onSaveEdit"
    @destroy="onDestroy"
  >
    <template #display="{ item }">
      <LazyImage
        v-if="item.smallUrl"
        :src="item.smallUrl"
        :variant="LazyImageVariantsEnum.WIDE_SMALL"
        :alt="item.name"
        class="image-thumbnail"
      />
      <span>{{ item.name }}</span>
    </template>

    <template #actions="{ item }">
      <Btn
        v-tooltip="t('labels.image.enabled')"
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.TRANSPARENT"
        @click="toggleField(item, 'enabled')"
      >
        <i
          class="fad fa-ban"
          :class="!item.enabled ? 'text-warning' : 'text-muted'"
        />
      </Btn>
      <Btn
        v-tooltip="t('labels.image.global')"
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.TRANSPARENT"
        @click="toggleField(item, 'global')"
      >
        <i
          class="fad fa-globe"
          :class="!item.global ? 'text-warning' : 'text-muted'"
        />
      </Btn>
      <Btn
        v-tooltip="t('labels.image.background')"
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.TRANSPARENT"
        @click="toggleField(item, 'background')"
      >
        <i
          class="fad fa-image"
          :class="item.background ? 'text-info' : 'text-muted'"
        />
      </Btn>
    </template>

    <template #edit>
      <FormInput
        v-model="editForm.caption"
        name="edit-caption"
        translation-key="image.caption"
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
.image-thumbnail {
  width: 80px;
  flex-shrink: 0;
}
</style>

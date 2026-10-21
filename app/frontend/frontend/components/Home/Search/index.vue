<script lang="ts">
export default {
  name: "HomeSearch",
};
</script>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormInputGroup from "@/shared/components/base/FormInputGroup/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  autofocus?: boolean;
};

withDefaults(defineProps<Props>(), {
  autofocus: false,
});

const { t } = useI18n();
const router = useRouter();

const searchQuery = ref<string | undefined>();

const search = async () => {
  if (!searchQuery.value) return;

  await router.push({
    name: "ships",
    query: { searchCont: searchQuery.value },
  });
};
</script>

<template>
  <form role="search" @submit.prevent="search">
    <FormInputGroup>
      <FormInput
        v-model="searchQuery"
        name="search"
        :size="InputSizesEnum.LARGE"
        :autofocus="autofocus"
        translation-key="home.search"
        no-label
        clearable
      />
      <Btn
        type="submit"
        :aria-label="t('labels.home.submitSearch')"
        :size="BtnSizesEnum.LG"
        data-test="home-search-submit"
      >
        <i class="fa-light fa-search" />
      </Btn>
    </FormInputGroup>
  </form>
</template>

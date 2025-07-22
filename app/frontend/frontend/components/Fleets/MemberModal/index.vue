<script lang="ts">
export default {
  name: "MemberModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { Fleet, FleetMemberCreateInput } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useCreateFleetMember as useCreateFleetMemberMutation } from "@/services/fyApi";
import { BtnSizesEnum, BtnTypesEnum } from "@/shared/components/base/Btn/types";

const { t } = useI18n();

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const submitting = ref(false);

const form = ref<FleetMemberCreateInput>({});

onMounted(() => {
  setupForm();
});

const setupForm = () => {
  form.value = {
    username: undefined,
  };
};

const comlink = useComlink();

const mutation = useCreateFleetMemberMutation();

const save = async () => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      data: form.value,
    })
    .then((member) => {
      comlink.emit("fleet-member-invited", member);
      comlink.emit("close-modal");
    })
    .catch((error) => {
      console.error(error);
    })
    .finally(() => {
      submitting.value = false;
    });
};
</script>

<template>
  <ValidationObserver v-slot="{ handleSubmit }" slim>
    <Modal v-if="fleet && form" :title="t('headlines.fleets.inviteMember')">
      <form
        :id="`fleet-member-${fleet.id}`"
        @submit.prevent="handleSubmit(save)"
      >
        <div class="row">
          <div class="col-12">
            <ValidationProvider
              v-slot="{ errors }"
              vid="username"
              rules="required|alpha_dash|user"
              :name="t('labels.username')"
              :slim="true"
            >
              <FormInput
                v-model="form.username"
                name="username"
                :error="errors[0]"
                :no-label="true"
                :autofocus="true"
              />
            </ValidationProvider>
          </div>
        </div>
      </form>
      <template #footer>
        <div class="float-sm-right">
          <Btn
            :form="`fleet-member-${fleet.id}`"
            :loading="submitting"
            :type="BtnTypesEnum.SUBMIT"
            :size="BtnSizesEnum.LARGE"
            :inline="true"
          >
            {{ t("actions.fleet.members.invite") }}
          </Btn>
        </div>
      </template>
    </Modal>
  </ValidationObserver>
</template>

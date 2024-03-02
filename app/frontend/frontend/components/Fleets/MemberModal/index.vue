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
                id="username"
                v-model="form.username"
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
            type="submit"
            size="large"
            :inline="true"
          >
            {{ t("actions.fleet.members.invite") }}
          </Btn>
        </div>
      </template>
    </Modal>
  </ValidationObserver>
</template>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import { Fleet, FleetMemberCreateInput } from "@/services/fyApi";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useComlink } from "@/shared/composables/useComlink";

const { t } = useI18n();

const { displayAlert } = useNoty(t);

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

const { fleetMembers: fleetMembersService } = useApiClient();

const comlink = useComlink();

const save = async () => {
  submitting.value = true;

  try {
    const member = await fleetMembersService.createMember({
      fleetSlug: props.fleet.slug,
      requestBody: form.value,
    });

    comlink.emit("fleet-member-invited", member);
    comlink.emit("close-modal");
  } catch (error) {
    console.error(error);
    // displayAlert({
    //   text: t(response.error),
    // });
  }
  submitting.value = false;
};
</script>

<script lang="ts">
export default {
  name: "MemberModal",
};
</script>

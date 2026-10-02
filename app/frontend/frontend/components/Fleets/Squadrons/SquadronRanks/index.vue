<script lang="ts">
export default {
  name: "SquadronRanks",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import {
  type FleetSquadronRole,
  FleetSquadronRoleKeyEnum,
  getFleetSquadronRolesQueryKey,
  useUpdateFleetSquadronRole,
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  fleetSlug: string;
  ranks: FleetSquadronRole[];
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
});

const RIGHTS = ["singleHolder", "managesMembers", "managesRanks"] as const;

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();
const submitting = ref(false);

const initialValues = computed(() =>
  Object.fromEntries(props.ranks.map((rank) => [rank.key, rank.name])),
);

const { defineField, handleSubmit, meta, resetForm } = useForm<
  Record<string, string>
>({
  initialValues: initialValues.value,
});

const fields = Object.fromEntries(
  Object.values(FleetSquadronRoleKeyEnum).map((key) => [key, defineField(key)]),
);

const mutation = useUpdateFleetSquadronRole();

// One request per renamed rank: the four are separate rows, and a name left
// alone is not written again. Settled rather than all-or-nothing, because the
// renames that went through are saved whatever happens to the rest.
const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const renamed = props.ranks.filter((rank) => values[rank.key] !== rank.name);

  const results = await Promise.allSettled(
    renamed.map((rank) =>
      mutation.mutateAsync({
        fleetSlug: props.fleetSlug,
        id: rank.id,
        data: { name: values[rank.key] },
      }),
    ),
  );

  await queryClient.invalidateQueries({
    queryKey: getFleetSquadronRolesQueryKey(props.fleetSlug),
  });

  const failure = results.find(
    (result): result is PromiseRejectedResult => result.status === "rejected",
  );

  if (failure) {
    const { message } = validationErrorFrom(failure.reason);
    displayAlert({
      text: message || t("messages.fleet.squadrons.ranks.update.failure"),
    });
  } else {
    resetForm({ values });
    displaySuccess({
      text: t("messages.fleet.squadrons.ranks.update.success"),
    });
  }

  submitting.value = false;
});
</script>

<template>
  <form id="squadron-ranks-form" @submit.prevent="onSubmit">
    <p class="squadron-ranks__hint">
      {{ t("labels.fleet.squadrons.ranksHint") }}
    </p>
    <div class="squadron-ranks">
      <Panel
        v-for="rank in ranks"
        :key="rank.id"
        :data-test="`squadron-rank-${rank.key}`"
      >
        <PanelHeading :level="HeadingLevelEnum.H3">
          {{ rank.name }}
        </PanelHeading>
        <PanelBody>
          <ul class="squadron-rank-rights">
            <li
              v-for="right in RIGHTS"
              :key="right"
              class="squadron-rank-right"
              :class="{ active: rank[right] }"
            >
              <i
                :class="
                  rank[right]
                    ? 'fa-solid fa-check text-success'
                    : 'fa-solid fa-times text-muted'
                "
              />
              {{ t(`labels.fleet.squadrons.rankRights.${right}`) }}
            </li>
          </ul>
          <FormInput
            v-if="editable"
            v-model="fields[rank.key][0].value"
            v-bind="fields[rank.key][1].value"
            :name="rank.key"
            :label="t('labels.fleet.squadrons.rankName')"
            rules="required"
            :data-test="`squadron-rank-name-${rank.key}`"
          />
        </PanelBody>
      </Panel>
    </div>
    <FormActions
      v-if="editable"
      :submitting="submitting"
      form-id="squadron-ranks-form"
      :dirty="meta.dirty"
      @cancel="resetForm()"
    />
  </form>
</template>

<style lang="scss" scoped>
.squadron-ranks__hint {
  color: var(--color-text-dim);
}

.squadron-ranks {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
}

.squadron-rank-rights {
  list-style: none;
  padding: 0;
  margin: 0 0 12px;
}

.squadron-rank-right {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 0;
  opacity: 0.5;

  &.active {
    opacity: 1;
  }

  i {
    width: 16px;
    text-align: center;
  }
}
</style>

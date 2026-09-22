import { useForm } from "vee-validate";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type FleetSquadron,
  useCreateFleetSquadron,
  useUpdateFleetSquadron,
} from "@/services/fyApi";

// The API's own limits, drawn under each field as a running count.
export const SHORT_DESCRIPTION_MAX = 255;
export const DESCRIPTION_MAX = 5000;

export type SquadronFormFields = ReturnType<typeof useSquadronForm>["fields"];

export type SquadronFormFieldProps = ReturnType<
  typeof useSquadronForm
>["fieldProps"];

/*
 * One form across both tabs of the editor. The fields are declared here rather
 * than in the tab that draws them, so switching tabs is a change of view and
 * not a change of form: everything is written in one call, and a squadron is
 * created with its pictures already on it -- the direct upload hands back a
 * signed id before any record exists, so there is nothing to wait for.
 */
export const useSquadronForm = (
  fleet: Ref<Fleet>,
  squadron?: Ref<FleetSquadron | undefined>,
) => {
  const { t } = useI18n();
  const { displaySuccess, displayAlert } = useAppNotifications();
  const comlink = useComlink();
  const router = useRouter();

  const isEdit = computed(() => !!squadron?.value);

  const submitting = ref(false);

  const validationSchema = {
    name: "required|min:2|max:255",
    // What the card carries, so it stays short.
    shortDescription: `max:${SHORT_DESCRIPTION_MAX}`,
    description: `max:${DESCRIPTION_MAX}`,
  };

  const { defineField, handleSubmit, setErrors, meta } = useForm({
    initialValues: {
      name: squadron?.value?.name ?? "",
      shortDescription: squadron?.value?.shortDescription ?? "",
      description: squadron?.value?.description ?? "",
      // The picker cannot express "no colour", so a squadron without one opens
      // on the neutral it is already drawn with rather than on black.
      color: squadron?.value?.color ?? "#8899aa",
      team: squadron?.value?.team ?? false,
      icon: undefined as string | undefined,
      logo: undefined as string | undefined,
      header: undefined as string | undefined,
    },
    // The tab that is not on screen is unmounted, and its fields go with it.
    // Without this a squadron saved from the details tab would clear whatever
    // pictures were chosen on the other one.
    keepValuesOnUnmount: true,
  });

  const [name, nameProps] = defineField("name");
  const [shortDescription, shortDescriptionProps] =
    defineField("shortDescription");
  const [description, descriptionProps] = defineField("description");
  const [color, colorProps] = defineField("color");
  const [team, teamProps] = defineField("team");
  const [icon, iconProps] = defineField("icon");
  const [logo, logoProps] = defineField("logo");
  const [header, headerProps] = defineField("header");

  const fields = reactive({
    name,
    shortDescription,
    description,
    color,
    team,
    icon,
    logo,
    header,
  });

  const fieldProps = reactive({
    name: nameProps,
    shortDescription: shortDescriptionProps,
    description: descriptionProps,
    color: colorProps,
    team: teamProps,
    icon: iconProps,
    logo: logoProps,
    header: headerProps,
  });

  const createMutation = useCreateFleetSquadron();
  const updateMutation = useUpdateFleetSquadron();

  const onSubmit = handleSubmit(async (values) => {
    submitting.value = true;

    const data = {
      name: values.name,
      shortDescription: values.shortDescription || null,
      description: values.description || null,
      color: values.color || null,
      team: values.team,
      // Passed through rather than coerced: `undefined` keeps what is attached,
      // `null` is the field saying it was cleared, and a signed id replaces it.
      icon: values.icon,
      logo: values.logo,
      header: values.header,
    };

    const request = isEdit.value
      ? updateMutation.mutateAsync({
          fleetSlug: fleet.value.slug,
          slug: squadron!.value!.slug,
          data,
        })
      : createMutation.mutateAsync({ fleetSlug: fleet.value.slug, data });

    await request
      .then((saved) => {
        displaySuccess({
          text: isEdit.value
            ? t("messages.fleet.squadrons.update.success")
            : t("messages.fleet.squadrons.create.success"),
        });
        comlink.emit(
          isEdit.value ? "fleet-squadron-updated" : "fleet-squadron-created",
        );

        void router.push({
          name: "fleet-squadron",
          params: { slug: fleet.value.slug, squadron: saved.slug },
        });
      })
      .catch((error) => {
        const { message, formErrors } = validationErrorFrom(error);

        setErrors(formErrors);

        displayAlert({
          text:
            message ||
            (isEdit.value
              ? t("messages.fleet.squadrons.update.failure")
              : t("messages.fleet.squadrons.create.failure")),
        });
      })
      .finally(() => {
        submitting.value = false;
      });
  });

  const handleCancel = () => {
    void router.push(
      squadron?.value
        ? {
            name: "fleet-squadron",
            params: { slug: fleet.value.slug, squadron: squadron.value.slug },
          }
        : { name: "fleet-squadrons", params: { slug: fleet.value.slug } },
    );
  };

  return {
    fields,
    fieldProps,
    validationSchema,
    meta,
    submitting,
    onSubmit,
    handleCancel,
  };
};

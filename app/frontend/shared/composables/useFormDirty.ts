import type { MaybeRefOrGetter, Ref } from "vue";

// An empty field reads the same however a control writes it: a toggle switched
// on and off again ends at `false`, a cleared input at "", an emptied multiselect
// at [], where the form may have started at undefined.
const isEmpty = (value: unknown) =>
  value === null ||
  value === undefined ||
  value === false ||
  value === "" ||
  (Array.isArray(value) && value.length === 0);

const normalize = (value: unknown) =>
  isEmpty(value) ? "" : JSON.stringify(value);

// vee-validate's own `meta.dirty` never turns true behind a FormInput: it
// syncs its value through resetField, which moves the initial value along with
// it. So the values are compared against what the form opened with instead.
//
// A getter or ref for the initial values is read on every comparison, for a
// form that re-fills itself from a refetched record: it is compared with the
// record as it is now, not as it was when the form opened.
export const useFormDirty = <T extends object>(
  values: T | Ref<T>,
  initialValues: MaybeRefOrGetter<T>,
) =>
  computed(() => {
    const initial = toValue(initialValues) as Record<string, unknown>;
    const current = toValue(values) as Record<string, unknown>;

    // Both sides' keys: a field the form opened without a value for is still
    // an edit once it has one.
    const keys = new Set([...Object.keys(initial), ...Object.keys(current)]);

    return [...keys].some(
      (key) => normalize(current[key]) !== normalize(initial[key]),
    );
  });

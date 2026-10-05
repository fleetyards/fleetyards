import type { Ref } from "vue";

const normalize = (value: unknown) =>
  value === null || value === undefined ? "" : JSON.stringify(value);

// vee-validate's own `meta.dirty` never turns true behind a FormInput: it
// syncs its value through resetField, which moves the initial value along with
// it. So the values are compared against what the form opened with instead.
export const useFormDirty = <T extends object>(
  values: T | Ref<T>,
  initialValues: T,
) => {
  const snapshot = Object.fromEntries(
    Object.entries(initialValues).map(([key, value]) => [
      key,
      normalize(value),
    ]),
  );

  return computed(() => {
    const current = toValue(values) as Record<string, unknown>;

    return Object.keys(snapshot).some(
      (key) => normalize(current[key]) !== snapshot[key],
    );
  });
};

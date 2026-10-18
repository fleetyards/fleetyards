import {
  type InjectionKey,
  type MaybeRefOrGetter,
  inject,
  onUnmounted,
  toValue,
} from "vue";

type DirtySource = () => boolean;

type RegisterDirtySource = (source: DirtySource) => () => void;

export const modalDirtyKey: InjectionKey<RegisterDirtySource> =
  Symbol("modalDirty");

// Tells the modal around this component whether closing it now would lose
// something, so it asks first. It works from any depth - a picker inside its
// caller's modal is heard - and every component that reports is asked.
//
// A form passes `useFormDirty(values, initialValues)`. Once it has saved, it
// closes the modal with force (`comlink.emit("close-modal", true)`): its values
// still differ from where they started, and nothing is lost.
export const useModalDirty = (dirty: MaybeRefOrGetter<boolean>) => {
  const register = inject(modalDirtyKey, undefined);

  if (!register) return;

  onUnmounted(register(() => toValue(dirty)));
};

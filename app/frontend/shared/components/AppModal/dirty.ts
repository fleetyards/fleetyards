import { type InjectionKey, inject, onUnmounted } from "vue";

type DirtySource = () => boolean;

type RegisterDirtySource = (source: DirtySource) => () => void;

export const modalDirtyKey: InjectionKey<RegisterDirtySource> =
  Symbol("modalDirty");

// Tells the modal around this component whether closing it now would lose
// something. Unlike an exposed `dirty`, it works from any depth, so content
// wrapped in another component - a picker inside its caller's modal - is heard.
// Once a source is registered, the modal no longer guesses from form events.
export const useModalDirty = (source: DirtySource) => {
  const register = inject(modalDirtyKey, undefined);

  if (!register) return;

  onUnmounted(register(source));
};

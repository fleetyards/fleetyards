import { type PanelTonesEnum } from "@/shared/components/base/Panel/types";

export type AppConfirmOptions = {
  text?: string;
  onConfirm?: () => void | Promise<unknown>;
  onClose?: () => void | Promise<unknown>;
  confirmText?: string;
  cancelText?: string;
  /*
   * What the decision means, in the same vocabulary as a panel's tone. The
   * toasts signal their kind with a coloured edge; here the panel's end-caps
   * carry it, which is the current idiom for the same idea. `error` also turns
   * the confirming button danger-toned.
   */
  tone?: `${PanelTonesEnum}`;
};

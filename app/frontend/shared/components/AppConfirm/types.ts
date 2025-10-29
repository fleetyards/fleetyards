export type AppConfirmOptions = {
  text?: string;
  onConfirm?: () => void | Promise<unknown>;
  onClose?: () => void | Promise<unknown>;
  confirmText?: string;
  cancelText?: string;
};

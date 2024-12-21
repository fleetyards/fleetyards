import { useNoty } from "@/shared/composables/useNoty";

const getMessages = function getMessages() {
  return window.FLASH || {};
};

const cleanMessages = function cleanMessages() {
  if (!window.FLASH) {
    return;
  }
  window.FLASH = {};
};

export const useFlash = () => {
  const { displayNotification } = useNoty();

  const checkMessages = () => {
    const messages = getMessages();
    cleanMessages();

    if (!messages) {
      return undefined;
    }

    const keys = Object.keys(messages);

    keys.forEach((key) => {
      const message = messages[key];

      if (!message) {
        return;
      }

      displayNotification({
        text: message,
        type: key as "success" | "info" | "warning" | "error",
      });
    });
  };

  onMounted(() => {
    checkMessages();
  });
};

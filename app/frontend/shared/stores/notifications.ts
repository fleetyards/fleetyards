import { defineStore } from "pinia";
import { type AppNotification } from "@/shared/components/AppNotifications/types";

type NotificationsState = {
  messages: AppNotification[];
};

export const useNotificationsStore = defineStore("notifications", {
  state: (): NotificationsState => ({
    messages: [],
  }),
  actions: {
    addMessage(message: AppNotification) {
      this.messages.push(message);
    },
    removeMessage(id: string) {
      this.messages = this.messages.filter((message) => message.id !== id);
    },
    hideMessage(id: string) {
      const message = this.messages.find((message) => message.id === id);

      if (!message) {
        return;
      }

      message.visible = false;

      this.messages = this.messages.map((m) =>
        m.id === id ? { ...m, ...message } : m,
      );

      if (!message.persist) {
        this.removeMessage(id);
      }
    },
  },
});

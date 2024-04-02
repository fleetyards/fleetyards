import Noty from "noty";
import { isBefore, addSeconds } from "date-fns";
import { useI18n } from "@/shared/composables/useI18n";

export interface FleetyardsNotyOptions extends Noty.Options {
  icon?: string;
  catergory?: string;
  notifyInBackground?: boolean;
  timeout?: number | false;
  onConfirm?: () => void;
  onCancel?: () => void;
  onClose?: () => void;
}

export interface NotyButton extends Noty.Button {
  dom: HTMLElement;
}

Noty.overrideDefaults({
  callbacks: {
    onTemplate() {
      if (this.options.category === "confirm") {
        this.barDom.innerHTML = `
          <div class="noty_body">${this.options.text}</div>
        `;
        const buttons: string[] = [];
        this.options.buttons.forEach((button: NotyButton) => {
          const inner = document.createElement("div");
          inner.setAttribute("class", "panel-btn-inner");
          inner.textContent = button.dom.textContent;
          button.dom.removeChild(button.dom.childNodes[0]);
          button.dom.appendChild(inner);
          buttons.push(button.dom.outerHTML as string);
        });

        this.barDom.innerHTML += `
          <div class="noty_buttons">
            ${buttons.join("")}
          </div>
          <div class="noty_close_button override">
            <i class="fal fa-times"></i>
          </div>
          <div class="noty_progressbar"></div>
        `;
      }

      if (this.options.category === "notification") {
        this.barDom.innerHTML = `
          <div class="noty_body">${this.options.text}</div>
        `;

        if (this.options.icon) {
          this.barDom.innerHTML += `
            <div class="noty_icon"><img src="${this.options.icon}" alt="icon" /></div>
          `;
        }

        this.barDom.innerHTML += `
          <div class="noty_close_button override">
            <i class="fal fa-times"></i>
          </div>
          <div class="noty_progressbar"></div>
        `;
      }
    },
  },
});

const notifyPermissionGranted = () =>
  "Notification" in window && window.Notification.permission === "granted";

const displayDesktopNotification = (message: string) => {
  const notification = new window.Notification(message, {
    // eslint-disable-next-line global-require
    icon: `${window.FRONTEND_ENDPOINT}${require("@/images/favicon.png")}`,
  });

  return notification;
};

const displayNativeNotification = (message: string) => {
  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.ready.then(
      (registration) => {
        if (!registration.showNotification) {
          return;
        }

        registration.showNotification(message, {
          icon: `${window.FRONTEND_ENDPOINT}/images/favicon.png`,
          vibrate: [200, 100, 200, 100, 200, 100, 200],
        });
      },
      () => {
        displayDesktopNotification(message);
      },
    );
  } else {
    displayDesktopNotification(message);
  }
};

const notifyInBackground = (text: string) => {
  displayNativeNotification(text);
};

let lastNotyText = "";
let lastNotyAt: Date | null = null;

const notyBackoff = (text: string) => {
  if (lastNotyText !== text) {
    return false;
  }

  const lastNoty = JSON.parse(JSON.stringify(lastNotyAt));

  if (isBefore(addSeconds(new Date(lastNoty), 2), new Date())) {
    return false;
  }

  return true;
};

const displayNotification = (options: FleetyardsNotyOptions) => {
  const defaults = {
    text: null,
    type: "info",
    timeout: 3000,
    icon: null,
    notifyInBackground: true,
    ...options,
  };

  if (defaults.text && !notyBackoff(defaults.text)) {
    lastNotyAt = new Date();
    lastNotyText = defaults.text;

    let displayText = defaults.text;
    if (
      document.visibilityState !== "visible" &&
      notifyPermissionGranted() &&
      defaults.notifyInBackground
    ) {
      notifyInBackground(displayText.replace(/(<([^>]+)>)/gi, ""));
    } else {
      if (Array.isArray(displayText)) {
        displayText = displayText.join("<br>");
      }
      new Noty({
        text: displayText,
        type: defaults.type,
        icon: defaults.icon,
        timeout: defaults.timeout,
        category: "notification",
        layout: "topRight",
        theme: "metroui",
        closeWith: ["click", "button"],
        animation: {
          open: "noty_effects_open",
          close: "noty_effects_close",
        },
        progressBar: true,
      } as FleetyardsNotyOptions).show();
    }
  }
};

export const useNoty = () => {
  const { t } = useI18n();

  const displaySuccess = function success(options: FleetyardsNotyOptions) {
    displayNotification({
      ...options,
      type: "success",
    });
  };

  const displayInfo = function info(options: FleetyardsNotyOptions) {
    displayNotification({
      ...options,
      type: "info",
    });
  };

  const displayWarning = function warning(options: FleetyardsNotyOptions) {
    displayNotification({
      ...options,
      type: "warning",
    });
  };

  const displayAlert = function alert(options: FleetyardsNotyOptions) {
    displayNotification({
      timeout: 10000,
      ...options,
      type: "error",
      notifyInBackground: false,
    });
  };

  const displayConfirm = function displayConfirm(
    options: FleetyardsNotyOptions,
  ) {
    const defaults = {
      text: null,
      layout: "center",
      confirmBtnLayout: "danger",
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      onConfirm: () => {},
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      onCancel: () => {},
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      onClose: () => {},
      ...options,
    };

    let btnClass = "";
    if (defaults.confirmBtnLayout !== "default") {
      btnClass = ` btn-${defaults.confirmBtnLayout}`;
    }

    const n = new Noty({
      text: defaults.text,
      layout: defaults.layout,
      theme: "metroui",
      closeWith: ["click", "button"],
      id: "noty-confirm",
      category: "confirm",
      animation: {
        open: "noty_effects_open",
        close: "noty_effects_close",
      },
      buttons: [
        Noty.button(t("actions.cancel"), "panel-btn panel-btn-inline", () => {
          n.close();
          defaults.onCancel();
        }),
        Noty.button(
          t("actions.confirm"),
          `panel-btn panel-btn-inline${btnClass}`,
          () => {
            n.close();
            defaults.onConfirm();
          },
          { "data-status": "ok" },
        ),
      ],
      callbacks: {
        onClose() {
          defaults.onClose();
        },
      },
    } as FleetyardsNotyOptions);

    n.show();
  };

  const requestBrowserPermission = () => {
    if (!("Notification" in window) || notifyPermissionGranted()) {
      return;
    }

    window.Notification.requestPermission((permission) => {
      if (permission === "granted") {
        displayNativeNotification(t("messages.notification.granted"));
      }
    });
  };

  return {
    displaySuccess,
    displayInfo,
    displayWarning,
    displayAlert,
    displayConfirm,
    requestBrowserPermission,
  };
};

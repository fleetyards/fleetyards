// Safari has no Vibration API. From iOS 18 on, toggling a native switch
// control buzzes the Taptic Engine, and a label click toggles one without it
// ever being shown - the only way a web page on an iPhone gets a tick.
let iosSwitch: HTMLLabelElement | undefined;

const iosTick = () => {
  if (!iosSwitch) {
    const label = document.createElement("label");
    const input = document.createElement("input");

    input.type = "checkbox";
    input.setAttribute("switch", "");
    input.tabIndex = -1;
    label.setAttribute("aria-hidden", "true");
    label.style.display = "none";
    label.appendChild(input);
    document.body.appendChild(label);

    iosSwitch = label;
  }

  iosSwitch.click();
};

/*
 * A short, light tick for a gesture that has landed: a held row turning into a
 * selection, a swiped row passing the point where letting go will act. Best
 * effort - a device that can do neither simply stays silent.
 */
export const hapticTick = () => {
  if (typeof navigator === "undefined") {
    return;
  }

  if ("vibrate" in navigator) {
    navigator.vibrate(10);

    return;
  }

  iosTick();
};

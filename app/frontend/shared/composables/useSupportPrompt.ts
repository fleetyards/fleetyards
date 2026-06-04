import { useNotificationsStore } from "@/shared/stores/notifications";
import { MessageTypesEnum } from "@/shared/components/AppNotifications/types";
import { v4 as uuidv4 } from "uuid";

const STORAGE_KEY = "fy.support-prompt";
const COOLDOWN_DAYS = 90;
const SESSION_LOGIN_FLAG = "fy.support-prompt.login-counted";
const SESSION_VISIT_FLAG = "fy.support-prompt.visit-counted";

export type SupportPromptContext =
  | "hangarSync"
  | "vehicleAdded"
  | "fleetCreated"
  | "loginMilestone"
  | "visitMilestone";

type Counters = Record<string, number>;

type StoredState = {
  lastShownAt?: string;
  counters?: Counters;
};

const readState = (): StoredState => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as StoredState) : {};
  } catch {
    return {};
  }
};

const writeState = (state: StoredState) => {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch {
    // ignore storage failures
  }
};

const daysSince = (iso?: string): number | null => {
  if (!iso) return null;
  const parsed = Date.parse(iso);
  if (Number.isNaN(parsed)) return null;
  return (Date.now() - parsed) / 86_400_000;
};

export const useSupportPrompt = () => {
  const notificationsStore = useNotificationsStore();

  const canShow = (): boolean => {
    const since = daysSince(readState().lastShownAt);
    return since === null || since > COOLDOWN_DAYS;
  };

  const recordShown = () => {
    const state = readState();
    state.lastShownAt = new Date().toISOString();
    writeState(state);
  };

  const counterValue = (name: string): number => {
    return readState().counters?.[name] ?? 0;
  };

  const incrementCounter = (name: string): number => {
    const state = readState();
    const counters = state.counters ?? {};
    const next = (counters[name] ?? 0) + 1;
    counters[name] = next;
    state.counters = counters;
    writeState(state);
    return next;
  };

  const dispatchNotification = (
    context: SupportPromptContext,
    meta?: Record<string, unknown>,
  ) => {
    const notificationId = uuidv4();

    notificationsStore.addMessage({
      id: notificationId,
      type: MessageTypesEnum.INFO,
      visible: true,
      persist: true,
      timeout: false,
      component: () => import("@/shared/components/SupportHint/index.vue"),
      componentProps: {
        context,
        meta,
        notificationId,
      },
    });
  };

  const notify = (
    context: SupportPromptContext,
    meta?: Record<string, unknown>,
  ) => {
    if (!canShow()) return false;

    recordShown();
    dispatchNotification(context, meta);

    return true;
  };

  const forceNotify = (
    context: SupportPromptContext,
    meta?: Record<string, unknown>,
  ) => {
    dispatchNotification(context, meta);
  };

  const notifyIfMilestone = (
    counterName: string,
    milestones: number[],
    context: SupportPromptContext,
    meta?: Record<string, unknown>,
  ) => {
    const next = incrementCounter(counterName);
    if (!milestones.includes(next)) return false;
    return notify(context, { ...meta, count: next });
  };

  const notifyOnce = (
    flagName: string,
    context: SupportPromptContext,
    meta?: Record<string, unknown>,
  ) => {
    if (counterValue(flagName) > 0) return false;
    incrementCounter(flagName);
    return notify(context, meta);
  };

  const sessionFlagged = (key: string): boolean => {
    try {
      return sessionStorage.getItem(key) === "1";
    } catch {
      return false;
    }
  };

  const flagSession = (key: string) => {
    try {
      sessionStorage.setItem(key, "1");
    } catch {
      // ignore
    }
  };

  const sessionAlreadyCountedLogin = () => sessionFlagged(SESSION_LOGIN_FLAG);
  const markLoginCountedForSession = () => flagSession(SESSION_LOGIN_FLAG);
  const sessionAlreadyCountedVisit = () => sessionFlagged(SESSION_VISIT_FLAG);
  const markVisitCountedForSession = () => flagSession(SESSION_VISIT_FLAG);

  return {
    canShow,
    recordShown,
    counterValue,
    incrementCounter,
    notify,
    forceNotify,
    notifyIfMilestone,
    notifyOnce,
    sessionAlreadyCountedLogin,
    markLoginCountedForSession,
    sessionAlreadyCountedVisit,
    markVisitCountedForSession,
  };
};

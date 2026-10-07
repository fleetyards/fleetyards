import { useEventListener } from "@vueuse/core";
import { useSyncExtension } from "@/frontend/composables/useSyncExtension";
import {
  FleetyardsSyncAction,
  type FleetyardsSyncHealthPayload,
  type FleetyardsSyncMessage,
  type FleetyardsSyncSessionPayload,
} from "@/frontend/lib/FleetyardsSyncHandler";

export enum ExtensionVerificationState {
  // Nothing to verify, or already verified: nothing to offer.
  NONE = "none",
  DETECTING = "detecting",
  NOT_INSTALLED = "notInstalled",
  // Answers the health check, but from before this verification existed.
  OUTDATED = "outdated",
  NOT_SIGNED_IN = "notSignedIn",
  MISMATCH = "mismatch",
  READY = "ready",
}

type Options = {
  // What the token proves: a handle or an SID. Undefined while there is
  // nothing to verify.
  target: () => string | null | undefined;
  token: () => string | null | undefined;
  writeAction: FleetyardsSyncAction;
  removeAction: FleetyardsSyncAction;
  // The extension request for a token, the target included where it needs it.
  params: (token: string) => Record<string, unknown>;
  // Whether the signed-in RSI account can verify the target at all. Without
  // one, any signed-in account can try, and the extension says if it cannot.
  accountMatches?: (rsiHandle: string, target: string) => boolean;
  // Whether a write landed where the check will look, for an extension that
  // writes into whichever account the browser is signed in to by the time it
  // runs. Without one, a write goes where it was asked to.
  wroteToTarget?: (answer: FleetyardsSyncMessage, target: string) => boolean;
  // Starts the server's check; resolves once it has been asked for.
  check: () => Promise<void>;
  // The latest check's status, and the one it has while still running.
  checkStatus: () => string | null | undefined;
  pendingStatus: string;
  // Error keys for the extension's answers; any other failure is `failed`.
  errors: Record<number, string>;
  onRemoveFailed: () => void;
};

const sameHandle = (a?: string | null, b?: string | null) =>
  !!a && !!b && a.toLowerCase() === b.toLowerCase();

export const accountIsTarget = (rsiHandle: string, target: string) =>
  sameHandle(rsiHandle, target);

/*
 * Verifying through the FleetYards Sync extension: it writes the token where
 * the server's check looks, the check runs, and the extension takes the token
 * out again. Never leaves the token behind: it comes out once the check has
 * answered, when the modal closes or the page goes away, and after a write
 * that never answered or landed somewhere else.
 */
export const useExtensionVerification = (options: Options) => {
  const extension = useSyncExtension();

  const state = ref(ExtensionVerificationState.NONE);

  const rsiHandle = ref<string>();

  const error = ref<string>();

  const running = ref(false);

  // What the extension may have written, as it was asked: the removal goes to
  // the same place even if the modal's data has moved on since.
  const written = ref<{ params: Record<string, unknown> }>();

  // Set once the check has been asked for: before that, the token has to stay
  // where the check will look for it.
  const checkStarted = ref(false);

  // Whether the latest check was the extension's, so its answer can show next
  // to the button that started it.
  const checkedByExtension = ref(false);

  let closed = false;

  // Each detection answers for the target it was started with. A newer one,
  // or a closed modal, makes it stale.
  let detection = 0;

  const detect = async (target: string) => {
    const current = ++detection;
    const stale = () => closed || current !== detection;

    const health = await extension.health();
    if (stale()) return;

    if (health?.code !== 200) {
      state.value = ExtensionVerificationState.NOT_INSTALLED;
      return;
    }

    const actions = (health.payload as FleetyardsSyncHealthPayload)?.actions;
    if (!actions?.includes(options.writeAction)) {
      state.value = ExtensionVerificationState.OUTDATED;
      return;
    }

    const identity = await extension
      .request(FleetyardsSyncAction.IDENTIFY)
      .catch(() => undefined);
    if (stale()) return;

    const handle = (identity?.payload as FleetyardsSyncSessionPayload)?.handle;

    if (identity?.code !== 200 || !handle) {
      state.value = ExtensionVerificationState.NOT_SIGNED_IN;
      return;
    }

    rsiHandle.value = handle;
    state.value =
      !options.accountMatches || options.accountMatches(handle, target)
        ? ExtensionVerificationState.READY
        : ExtensionVerificationState.MISMATCH;
  };

  watch(
    options.target,
    (target) => {
      detection += 1;
      state.value = target
        ? ExtensionVerificationState.DETECTING
        : ExtensionVerificationState.NONE;
      if (target) void detect(target);
    },
    { immediate: true },
  );

  // After signing in to RSI, or switching account there, in another tab.
  const redetect = () => {
    const target = options.target();
    if (!target) return;

    state.value = ExtensionVerificationState.DETECTING;
    void detect(target);
  };

  // Fired while the page may already be going away, so nothing waits for it;
  // a failure is still reported, as the token would otherwise stay public.
  const removeToken = () => {
    const params = written.value?.params;
    if (!params) return;

    written.value = undefined;
    checkStarted.value = false;
    extension
      .request(options.removeAction, params)
      .then((answer) => {
        if (answer.code !== 200) throw new Error(answer.error);
      })
      .catch(options.onRemoveFailed);
  };

  const verify = async () => {
    const token = options.token();
    const target = options.target();
    if (!token || !target) return;

    error.value = undefined;
    checkedByExtension.value = false;
    running.value = true;

    // A token from an earlier try, since regenerated, comes out first; the
    // extension handles one request per page at a time, in order.
    removeToken();

    const params = options.params(token);

    try {
      const answer = await extension
        .request(options.writeAction, params)
        .catch(() => undefined);

      // No answer in time says nothing about whether the write landed, so the
      // token is treated as there: closing the modal takes it out.
      if (!answer) {
        written.value = { params };
        error.value = "failed";
        return;
      }

      if (answer.code !== 200) {
        error.value = options.errors[answer.code ?? 0] ?? "failed";
        return;
      }

      if ((answer.payload as { changed?: boolean })?.changed) {
        written.value = { params };
      }

      if (options.wroteToTarget && !options.wroteToTarget(answer, target)) {
        rsiHandle.value = (answer.payload as { handle?: string })?.handle;
        state.value = ExtensionVerificationState.MISMATCH;
        removeToken();
        return;
      }

      if (closed) {
        removeToken();
        return;
      }

      checkedByExtension.value = true;
      await options.check();
      checkStarted.value = true;
    } finally {
      running.value = false;
    }
  };

  // The check reads the page once and is done with it, so the token comes out
  // as soon as it has answered. Its status rather than the cooldown says so: a
  // job still queued when the cooldown ends has not read the page yet. One
  // that never answers leaves the token until the modal closes.
  watch(
    [written, checkStarted, options.checkStatus],
    ([write, started, status]) => {
      if (write && started && status !== options.pendingStatus) removeToken();
    },
  );

  const close = () => {
    closed = true;
    removeToken();
  };

  useEventListener(window, "pagehide", close);

  onBeforeUnmount(close);

  // A manual check answers under the manual steps again.
  const forgetCheck = () => {
    checkedByExtension.value = false;
  };

  return {
    state,
    rsiHandle,
    error,
    running,
    checkedByExtension,
    verify,
    redetect,
    forgetCheck,
  };
};

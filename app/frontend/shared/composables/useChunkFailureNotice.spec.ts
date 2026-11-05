import { nextTick } from "vue";
import { createPinia, setActivePinia } from "pinia";
import { useNotificationsStore } from "@/shared/stores/notifications";
import { chunkLoadFailed } from "@/shared/utils/ChunkReload";
import { useChunkFailureNotice } from "./useChunkFailureNotice";

describe("useChunkFailureNotice", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    chunkLoadFailed.value = false;
  });

  afterEach(() => {
    chunkLoadFailed.value = false;
  });

  it("stays quiet while chunks load", () => {
    useChunkFailureNotice();

    expect(useNotificationsStore().messages).toHaveLength(0);
  });

  it("keeps a notice up once a chunk could not be recovered", async () => {
    useChunkFailureNotice();

    chunkLoadFailed.value = true;
    await nextTick();

    const [message] = useNotificationsStore().messages;
    expect(message?.persist).toBe(true);
    expect(message?.timeout).toBe(false);
  });

  it("shows the notice for a failure from before the app mounted", () => {
    chunkLoadFailed.value = true;

    useChunkFailureNotice();

    expect(useNotificationsStore().messages).toHaveLength(1);
  });
});

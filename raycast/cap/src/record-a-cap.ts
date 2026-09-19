import { showFailureToast } from "@raycast/utils";
import { startFromPreferences, stopAndDeliver } from "./actions";
import { getSessions } from "./cap";

export default async function Command() {
  try {
    const active = await getSessions();
    if (active.length > 0) {
      await stopAndDeliver();
      return;
    }
    await startFromPreferences();
  } catch (error) {
    await showFailureToast(error, { title: "Cap recording failed" });
  }
}

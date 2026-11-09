// opencode TUI plugin: records the session this Rex pane shows, for
// rex-agent-resume.zsh. It runs in the TUI, which knows the pane and the session
// on screen; opencode's server plugins run in a shared service that knows neither.

import fs from "node:fs";
import path from "node:path";
// opencode redirects this to its own Solid instance, so the router and session
// data below are reactive here.
import { createEffect, createRoot } from "solid-js";

function setup(api) {
  const block = process.env.REX_BLOCK;
  if (!block) return;
  const dir = path.join(
    process.env.XDG_STATE_HOME || path.join(process.env.HOME, ".local/state"),
    "rex-agent-resume",
  );
  const file = path.join(dir, block.replace(/^block:/, ""));
  // The TUI's flags, to pass again on resume. opencode is a Bun binary, so its
  // argv starts with "bun" and the bundled script. The record has one line per
  // field; a multi-line prompt is not a flag.
  const args = process.argv.slice(2).filter((arg) => !arg.includes("\n"));

  // Runs again whenever the route changes or a session's parent loads.
  return createRoot((dispose) => {
    createEffect((recorded) => {
      const route = api.ui.router.current();
      if (route.type !== "session") return recorded;
      // A subagent's session is not the pane's; record its top-level one.
      const id = api.data.session.root(route.sessionID);
      if (!id || id === recorded) return recorded;
      try {
        fs.mkdirSync(dir, { recursive: true });
        fs.writeFileSync(
          file,
          ["opencode", id, process.cwd(), ...args].join("\n") + "\n",
        );
        return id;
      } catch {
        return recorded;
      }
    });
    return dispose;
  });
}

export default { id: "rex-agent-resume", setup };

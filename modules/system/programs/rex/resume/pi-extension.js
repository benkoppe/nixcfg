// pi extension that records the session this Rex pane shows, for
// rex-resume.zsh. pi reloads extensions and emits session_start again after
// /new, /resume and /fork, so the record names the session on screen.

import fs from "node:fs";
import path from "node:path";

export default function (pi) {
  const block = process.env.REX_BLOCK;
  if (!block) return;
  const dir = path.join(
    process.env.XDG_STATE_HOME || path.join(process.env.HOME, ".local/state"),
    "rex-resume",
  );
  const file = path.join(dir, block.replace(/^block:/, ""));
  // pi's flags, to pass again on resume. pi is a Bun binary, so its argv starts
  // with "bun" and the bundled script. The record has one line per field. A
  // multi-line argument is a prompt, not a flag, so leave it out.
  const args = process.argv.slice(2).filter((arg) => !arg.includes("\n"));

  pi.on("session_start", (_event, ctx) => {
    // Record only the interactive TUI. Print, json and rpc runs show nothing to
    // resume.
    if (ctx.mode !== "tui") return;
    // An ephemeral (--no-session) session has no file to resume.
    const session = ctx.sessionManager.getSessionFile();
    if (!session) return;
    try {
      fs.mkdirSync(dir, { recursive: true });
      fs.writeFileSync(
        file,
        ["pi", session, ctx.sessionManager.getCwd(), ...args].join("\n") + "\n",
      );
    } catch {}
  });
}

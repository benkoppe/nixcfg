// Reports the session on screen to Rex over OSC 7577, so Rex can resume it.
// https://www.superlogical.com/rex/docs/build/program-resume

import crypto from "node:crypto";
import fs from "node:fs";
import { createEffect, createRoot } from "solid-js";

const b64 = (s) => Buffer.from(s).toString("base64");

export default {
  id: "rex-resume",
  setup(api) {
    const token = process.env.OSC7577_TOKEN;
    // Keep child processes from reporting in our place.
    delete process.env.OSC7577_TOKEN;
    if (!token) return;

    // resume.lua keeps --auto.
    const flags = process.argv.includes("--auto") ? ["--auto"] : [];

    const report = (id) => {
      const argv = ["opencode", "--session", id, ...flags].map(b64).join(",");
      const cwd = b64(api.location?.directory ?? process.cwd());
      const body = `pid=${process.pid}:time=${Math.floor(Date.now() / 1000)}:argv=${argv}:cwd=${cwd}`;
      const mac = crypto.createHash("sha256").update(`${body}:${token}`).digest("hex");
      fs.writeSync(1, `\x1b]7577;${body}:mac=${mac}\x1b\\`);
    };

    return createRoot((dispose) => {
      createEffect((reported) => {
        const route = api.ui.router.current();
        // Report the top-level session, not a subagent's.
        const id = route.type === "session" && api.data.session.root(route.sessionID);
        if (!id || id === reported) return reported;
        // Write between frames, so the sequence can't land inside one.
        const write = () => {
          api.renderer.removeFrameCallback(write);
          report(id);
        };
        api.renderer.setFrameCallback(write);
        api.renderer.requestRender();
        return id;
      });
      return dispose;
    });
  },
};

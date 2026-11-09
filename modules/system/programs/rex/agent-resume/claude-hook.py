# Claude Code SessionStart hook: records the session this Rex pane shows, for
# rex-agent-resume.zsh. It also fires on /clear, /resume and compaction, so the
# record follows the conversation on screen.

import json
import os
import sys

import psutil

block = os.environ.get("REX_BLOCK")
if not block:
    sys.exit(0)
event = json.load(sys.stdin)
# A subagent's session is not the pane's.
if event.get("agent_id"):
    sys.exit(0)

# Claude may run this through a shell; the first ancestor that is not one is
# Claude, whose command line has the flags to pass again on resume.
claude = psutil.Process().parent()
while claude.name() in {"sh", "bash", "dash", "zsh"}:
    claude = claude.parent()
args = claude.cmdline()[1:]
# The record has one line per field; a multi-line prompt is not a flag.
args = [arg for arg in args if "\n" not in arg]

state = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
directory = os.path.join(state, "rex-agent-resume")
os.makedirs(directory, exist_ok=True)
with open(os.path.join(directory, block.removeprefix("block:")), "w") as record:
    record.write("\n".join(["claude", event["session_id"], event["cwd"], *args]) + "\n")

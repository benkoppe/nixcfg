# SessionStart command hook for Claude Code and Codex: records the session this
# Rex pane shows, for rex-agent-resume.zsh. Both agents also fire it when the
# conversation on screen changes (/clear, /resume, fork, compaction), so the
# record follows it. Usage: rex-agent-resume-hook claude|codex

import json
import os
import sys

import psutil

agent = sys.argv[1]
block = os.environ.get("REX_BLOCK")
if not block:
    sys.exit(0)
event = json.load(sys.stdin)
if event.get("hook_event_name", "SessionStart") != "SessionStart":
    sys.exit(0)
# A subagent's session is not the pane's.
if event.get("agent_id"):
    sys.exit(0)
# A Codex run from a shell inside another Codex inherits its thread ID.
thread = os.environ.get("CODEX_THREAD_ID")
if agent == "codex" and thread and thread != event["session_id"]:
    sys.exit(0)

# The agent may run this through a shell; the first ancestor that is not one is
# the agent, whose command line has the flags to pass again on resume.
process = psutil.Process().parent()
while process.name() in {"sh", "bash", "dash", "zsh"}:
    process = process.parent()
args = process.cmdline()[1:]
# The record has one line per field; a multi-line prompt is not a flag.
args = [arg for arg in args if "\n" not in arg]

state = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
directory = os.path.join(state, "rex-agent-resume")
os.makedirs(directory, exist_ok=True)
with open(os.path.join(directory, block.removeprefix("block:")), "w") as record:
    record.write("\n".join([agent, event["session_id"], event["cwd"], *args]) + "\n")

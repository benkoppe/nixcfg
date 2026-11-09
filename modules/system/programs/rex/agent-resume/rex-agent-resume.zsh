# Restarts coding agents in the Rex panes after the Rex server restarts.
# 
# While an agent runs, its integration writes a record for the pane (agent,
# session, directory, flags), in a file named after the pane's REX_BLOCK.
#   - The agent exits: the prompt comes back, and precmd deletes the record.
#   - Rex stops: it kills the shell before any prompt, so the record survives.
# A restored pane keeps its REX_BLOCK, so its new shell finds the record and
# resumes that session.

[[ -n $REX_BLOCK ]] || return

# Load the integrations, in Rex panes only. opencode's variable replaces
# cli.json's plugin list, which would drop other plugins if set everywhere.
export CLAUDE_CODE_PLUGIN_DIRS=@claudePlugin@
export OPENCODE_CLI_CONFIG_CONTENT='{"plugins":["@opencodePlugin@"]}'
# Codex has no such variable, so pass its hook as a config override.
@codexCommand@() {
  command @codexCommand@ -c 'hooks.SessionStart=[{hooks=[{type="command",command="rex-agent-resume-hook codex",timeout=10}]}]' "$@"
}

# Rex starts each pane's shell as a login shell. A nested zsh is not one, and
# may be running inside the agent.
[[ -o login ]] || return

typeset -g _rex_agent_dir=${XDG_STATE_HOME:-$HOME/.local/state}/rex-agent-resume
typeset -g _rex_agent_record=$_rex_agent_dir/${REX_BLOCK#block:}
typeset -g _rex_agent_resume_cmd

_rex_agent_forget() {
  [[ -e $_rex_agent_record ]] && rm -f -- $_rex_agent_record
}
autoload -Uz add-zsh-hook add-zle-hook-widget
add-zsh-hook precmd _rex_agent_forget

[[ -r $_rex_agent_record ]] || return

() {
  local -a record=("${(@f)$(<$_rex_agent_record)}") cmd
  local agent=$record[1] session=$record[2] cwd=$record[3] i arg
  case $agent in
    claude) cmd=(@claudeCommand@ --resume $session) ;;
    opencode) cmd=(@opencodeCommand@ --session $session) ;;
    codex) cmd=(@codexCommand@ resume $session) ;;
    pi) cmd=(@piCommand@ --session $session) ;;
    *) return ;;
  esac
  # Pass again only these flags from the agent's command line.
  for (( i = 4; i <= $#record; i++ )); do
    arg=$record[i]
    case $agent:$arg in
      claude:--dangerously-skip-permissions | claude:--model=* | claude:--permission-mode=* | \
      opencode:--auto | \
      codex:--dangerously-bypass-approvals-and-sandbox | codex:--approve-for-me | codex:--search | \
      codex:--model=* | codex:--sandbox=* | codex:--ask-for-approval=* | codex:--profile=* | codex:--add-dir=* | \
      pi:--no-tools | pi:-nt | pi:--no-builtin-tools | pi:-nbt | pi:--no-extensions | pi:-ne | \
      pi:--approve | pi:-a | pi:--no-approve | pi:-na | \
      pi:--extension=* | pi:--tools=* | pi:--exclude-tools=*)
        cmd+=($arg) ;;
      claude:--model | claude:--permission-mode | \
      codex:-m | codex:--model | codex:-s | codex:--sandbox | codex:-a | codex:--ask-for-approval | \
      codex:-p | codex:--profile | codex:--add-dir | \
      pi:-e | pi:--extension | pi:-t | pi:--tools | pi:-xt | pi:--exclude-tools)
        (( i < $#record )) && cmd+=($arg $record[++i]) ;;
    esac
  done
  _rex_agent_resume_cmd="cd -- ${(q-)cwd} && ${(j: :)${(q-)cmd[@]}}"
  add-zle-hook-widget line-init _rex_agent_resume_accept
  # A pane closed while its agent ran leaves a record no pane will match.
  rm -f -- $_rex_agent_dir/*(Nm+30)
}

# Runs the resume command as if typed, so it has job control and history.
_rex_agent_resume_accept() {
  add-zle-hook-widget -d line-init _rex_agent_resume_accept
  BUFFER=$_rex_agent_resume_cmd
  zle accept-line
}

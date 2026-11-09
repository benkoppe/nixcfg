# Brings back the coding agents and other commands in the Rex panes after the
# Rex server restarts.
#
# While an agent runs, its integration writes a record for the pane (agent,
# session, directory, flags), in a file named after the pane's REX_BLOCK. Other
# commands get one from preexec, and text typed at the prompt gets one as it
# changes.
#   - When the command exits, the prompt comes back and precmd deletes the record.
#   - When Rex stops, it kills the shell before any prompt, so the record stays.
# A restored pane keeps its REX_BLOCK, so its new shell finds the record and
# resumes it.

[[ -n $REX_BLOCK ]] || return

# Load the integrations, in Rex panes only. opencode's variable replaces
# cli.json's plugin list, which would drop other plugins if set everywhere.
export CLAUDE_CODE_PLUGIN_DIRS=@claudePlugin@
export OPENCODE_CLI_CONFIG_CONTENT='{"plugins":["@opencodePlugin@"]}'
# Codex has no such variable, so pass its hook as a config override.
@codexCommand@() {
  command @codexCommand@ -c 'hooks.SessionStart=[{hooks=[{type="command",command="rex-resume-hook codex",timeout=10}]}]' "$@"
}

# Rex starts each pane's shell as a login shell. A nested zsh is not one, and
# may be running inside the pane's agent or command.
[[ -o login ]] || return

typeset -g _rex_resume_dir=${XDG_STATE_HOME:-$HOME/.local/state}/rex-resume
typeset -g _rex_resume_record=$_rex_resume_dir/${REX_BLOCK#block:}
typeset -g _rex_resume_cmd _rex_resume_prefill _rex_resume_cursor _rex_resume_saved

_rex_resume_forget() {
  _rex_resume_saved=
  [[ -e $_rex_resume_record ]] && rm -f -- $_rex_resume_record
}

# Rex gives no warning before it stops, so save the prompt's text whenever it
# changes. A line starting with a space stays out of history, so out of this too.
_rex_resume_save() {
  [[ $CONTEXT == start && $CURSOR:$BUFFER != $_rex_resume_saved ]] || return 0
  _rex_resume_saved=$CURSOR:$BUFFER
  if [[ -z $BUFFER || $BUFFER == ' '* ]]; then
    [[ -e $_rex_resume_record ]] && rm -f -- $_rex_resume_record
  else
    [[ -d $_rex_resume_dir ]] || mkdir -p -- $_rex_resume_dir
    print -rl -- buffer ${(q+)BUFFER} $PWD $CURSOR >| $_rex_resume_record
  fi
  return 0
}

# Only a simple command with a listed program runs again. Any other command
# comes back on the prompt, because running it again could repeat its effects.
typeset -ga _rex_resume_rerun=(@rerunCommands@)
_rex_resume_remember() {
  [[ $1 != *$'\n'* && $1 != ' '* ]] || return
  local -a words=(${(z)3})
  local word kind=command simple=1
  for word in $words; do
    [[ $word == (\;|\&|\||\&\&|\|\||\|\&|\&\||\(|\)|\{|\}) ]] && kind=prompt simple=0
  done
  while [[ $words[1] == (*=*|command|exec|noglob|nocorrect) ]]; do
    shift words
  done
  (( $_rex_resume_rerun[(Ie)${words[1]:t}] )) || kind=prompt
  mkdir -p -- $_rex_resume_dir
  # Codex records its session only once it gets a message, so take a resumed
  # session's ID from the command line.
  local i subcommand session
  if (( simple )) && [[ ${words[1]:t} == @codexCommand@ ]]; then
    for (( i = 2; i <= $#words; i++ )); do
      case $words[i] in
        -c | --config | -i | --image | -m | --model | --local-provider | -p | --profile | \
        -s | --sandbox | -C | --cd | --add-dir | -a | --ask-for-approval | --enable | --disable | \
        --remote | --remote-auth-token-env) (( i++ )) ;;
        -*) ;;
        *)
          if [[ -z $subcommand ]]; then
            subcommand=$words[i]
            [[ $subcommand == resume ]] || break
          else
            session=${(Q)words[i]}
            break
          fi ;;
      esac
    done
  fi
  if [[ -n $session ]]; then
    print -rl -- codex $session $PWD ${(Q)words[2,-1]} >| $_rex_resume_record
  else
    print -rl -- $kind $1 $PWD >| $_rex_resume_record
  fi
}

autoload -Uz add-zsh-hook add-zle-hook-widget
add-zsh-hook precmd _rex_resume_forget
add-zsh-hook preexec _rex_resume_remember
add-zle-hook-widget line-pre-redraw _rex_resume_save

[[ -r $_rex_resume_record ]] || return

() {
  local -a record=("${(@f)$(<$_rex_resume_record)}") cmd
  local agent=$record[1] session=$record[2] cwd=$record[3] i arg line
  case $agent in
    command | prompt) line=$session ;;
    buffer) line=${(Q)session} _rex_resume_cursor=$record[4] ;;
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
  _rex_resume_cmd=${line:-${(j: :)${(q-)cmd[@]}}}
  # Without its directory, the command only comes back on the prompt.
  cd -- $cwd 2>/dev/null || _rex_resume_prefill=1
  [[ $agent == (prompt|buffer) ]] && _rex_resume_prefill=1
  add-zle-hook-widget line-init _rex_resume_accept
  # A pane closed while its command ran leaves a record no pane will match.
  rm -f -- $_rex_resume_dir/*(Nm+30)
}

# Types the resume command, and runs it unless it only comes back on the
# prompt. Running it as if typed gives it job control and history.
_rex_resume_accept() {
  add-zle-hook-widget -d line-init _rex_resume_accept
  BUFFER=$_rex_resume_cmd
  if (( _rex_resume_prefill )); then
    CURSOR=${_rex_resume_cursor:-$#BUFFER}
  else
    zle accept-line
  fi
}

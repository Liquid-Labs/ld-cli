help-work() {
  local PREFIX="${1:-}"

  handleSummary "${PREFIX}${cyan_u}work${reset} <action>: Manages the current unit of work." || cat <<EOF
${PREFIX}${cyan_u}work${reset} <action>:
  ${underline}save${reset} [-a|--all] [--backup-only|-b] [--message|-m=<version ][<path spec>...]:
    Save staged files to the local working branch. '--all' auto stages all known files (does not
    include new files) and saves them to the local working branch. '--backup-only' is useful if local commits
    have been made directly through 'git' and you want to push them.
  ${underline}stage${reset} [-a|--all] [-i|--interactive] [-r|--review] [-d|--dry-run] [<path spec>...]:
    Stages files for save.
  ${underline}status${reset} [-s|--select] [<name>]: Shows details for the current or named unit of work.
    Will enter interactive selection if no option and no current work or the
    '--select' option is given.
  ${underline}involve${reset} [-L|--no-link] [<repository name>]: Involves the current or named
    repository in the current unit of work. When involved, any packages in the
    newly involved project will be linked to the primary project in the unit of
    work. The '--no-link' option will suppress this behavior.
  ${underline}start${reset} <name>: Creates a new unit of work and adds the current repository (if any) to it.
  ${underline}stop${reset} [-k|--keep-checkout]: Stops working on the current unit of work. The
    master branch will be checked out for all involved projects unless
    '--keep-checkout' is used.
  ${underline}resume${reset} [<name>]: Resumes work on an existing unit of work.
  ${underline}edit${reset}: Opens a local project editor for all involved repositories.
  ${underline}report${reset}: Reports status of files in the current unit of work.
  ${underline}diff-master${reset}: Shows committed changes since branch from 'master' for all
    involved repositories.
  ${underline}ignore-rest${reset}: Adds any currently untracked files to '.gitignore'.
  ${underline}merge${reset}: Merges current work unit to master branches and updates mirrors.
  ${underline}qa${reset}: Checks the playground status and runs package audit, version check, and
    tests.
  ${underline}sync${reset} [--fetch-only|-f] [--no-work-master-merge|-M]:
    Synchronizes local project repos for all work. See `liq help work sync` for details.
  ${underline}test${reset}: Runs tests for each involved project in the current unit of work. See
    'project test' for details on options for the 'test' action.

A 'unit of work' is essentially a set of work branches across all involved projects. The first project involved in a unit of work is considered the primary project, which will effect automated linking when involving other projects.

${red_b}ALPHA Note:${reset} The 'stop' and 'resume' actions do not currently manage the work branches and only updates the 'current work' pointer.
EOF
}

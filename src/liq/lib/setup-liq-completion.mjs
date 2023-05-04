import { existsSync } from 'node:fs'
import * as fs from 'node:fs/promises'
import * as fsPath from 'node:path'

import { refresh } from '@liquid-labs/edit-section'
import { formatTerminalText } from '@liquid-labs/terminal-text'
import { wrap } from '@liquid-labs/wrap-text'

// bash config stuff
const possibleBashSystemCompletionPaths = [
  fsPath.resolve(fsPath.sep + 'etc', 'bash_completion.d'),
  fsPath.resolve(fsPath.sep + 'usr', 'local', 'etc', 'bash_completion.d')
]
const localBashCompletionPath = fsPath.resolve(process.env.HOME, '.bash_completion')
const possibleBashConfigFiles = [
  fsPath.join(process.env.HOME, '.bashrc'),
  fsPath.join(process.env.HOME, '.profile')
]
// zsh config stuff
const possibleZshSystemCompletionPaths = [fsPath.resolve(fsPath.sep + 'etc', 'profile.d')]
const possibleZshConfigFiles = [fsPath.join(process.env.HOME, '.zshrc')]

const setupLiqCompletion = async() => {
  const shell = process.env.SHELL?.replace(/.*?\/([A-Za-z0-9_-])/, '$1')
  if (shell === undefined) {
    console.warn("'SHELL' environment variable not set; cannot setup completion.")
    return
  }
  console.log(wrap(`Setting up ${shell} completion...`))

  let possibleSystemCompletionPaths, localCompletionPath, possibleConfigFiles, sourceConfig

  if (shell.endsWith('bash')) {
    possibleSystemCompletionPaths = possibleBashSystemCompletionPaths
    localCompletionPath = localBashCompletionPath
    possibleConfigFiles = possibleBashConfigFiles
    sourceConfig = ({ completionTarget }) => `[ -f '${completionTarget}' ] && . '${completionTarget}'`
  }
  else if (shell.endsWith('zsh')) {
    possibleSystemCompletionPaths = possibleZshSystemCompletionPaths
    localCompletionPath = localBashCompletionPath
    possibleConfigFiles = possibleZshConfigFiles
    sourceConfig = ({ completionTarget }) => `autoload -Uz compinit
compinit -u
autoload bashcompinit
bashcompinit
source ${completionTarget}`
  }
  else {
    console.warn(wrap(`Unknown shell type '${shell}'; cannot set up completion. Bash and zsh are supported.`))
    return
  }

  let completionConfigPath
  for (const testPath of possibleSystemCompletionPaths) {
    try {
      await fs.access(testPath, fs.constants.W_OK)
      completionConfigPath = testPath
      break
    }
    catch (e) {}
  }

  if (completionConfigPath === undefined) {
    if (!existsSync(localCompletionPath)) {
      await fs.mkdir(localCompletionPath, { recursive : true })
    }
    completionConfigPath = localCompletionPath
  }

  const completionSrc = fsPath.resolve(__dirname, 'completion.sh')
  const completionTarget = fsPath.join(completionConfigPath, 'liq')
  console.log(formatTerminalText(wrap(`Copying completion script to <code>${completionTarget}<rst>...`, { ignoreTags : true })))
  await fs.cp(completionSrc, completionTarget)

  let shellConfig
  for (const testConfig of possibleBashConfigFiles) {
    try {
      await fs.access(testConfig, fs.constants.W_OK)
      shellConfig = testConfig
      break
    }
    catch (e) {}
  }

  if (shellConfig === undefined) {
    shellConfig = possibleConfigFiles[0]
    await fs.writeFile(shellConfig, `# ${fsPath.basename(shellConfig)}  - executed for non-login interactive shells\n`)
  }
  console.log(formatTerminalText(wrap(`Writing completion sourcing to <code>${shellConfig}<rst>...`, { ignoreTags : true })))

  const contents = sourceConfig({ completionTarget })
  refresh({ contents, file : shellConfig, sectionKey : 'liq completion' })

  console.log(formatTerminalText(wrap(`To enable completion, you must open a new shell, or try:\n<em>source ${shellConfig}<rst>`, { ignoreTags : true })))
}

export { setupLiqCompletion }

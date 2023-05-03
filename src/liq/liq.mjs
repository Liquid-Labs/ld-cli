import { existsSync } from 'node:fs'
import * as fs from 'node:fs/promises'
import * as fsPath from 'node:path'

import { readFJSON } from '@liquid-labs/federated-json'
import { formatTerminalText } from '@liquid-labs/terminal-text'
import { Questioner } from '@liquid-labs/question-and-answer'
import { wrap } from '@liquid-labs/wrap-text'

import { LIQ_HOME } from './lib/constants'
import { processCommand } from './lib/process-command'
import { setupCLI } from './lib/setup-cli'
import { setupLiqCompletion } from './lib/setup-liq-completion'
import { setupLiqCore } from './lib/setup-liq-core'
import { setupLiqHome } from './lib/setup-liq-home'

const args = process.argv.slice(2)

const callEndpoint = async(args, bundle) => {
  const { fetchOpts, url } = await processCommand(args)

  fetchOpts.headers['X-CWD'] = fsPath.resolve(process.cwd()) // TODO: walk down until we find 'package.json'

  return await fetch(url, fetchOpts)
}

const addArg = ({ args, parameter, paramType, value }) => {
  if (!args.includes('--')) { args.push('--') }
  if (paramType?.match(/bool(?:ean)?/i) && value) {
    if (value === true) { // We want this inside because we don't want to run outer if/else if we're bool
      args.push(parameter)
    }
  }
  else {
    args.push(parameter + '=' + value)
  }
}

if (process.argv[2] !== 'setup' && existsSync(LIQ_HOME) !== true) {
  console.error(formatTerminalText(wrap(`It does not look like liq has been setup (did not find <code>${LIQ_HOME}<rst>). Try:\n<em>liq setup<rst>`, { ignoreTags : true })))
  process.exit(12)
}

(async() => {
  if (args.length === 1 && args[0] === 'setup') {
    if (await setupLiqHome() !== true) {
      console.log(wrap('\nBailing out. Review any messages above or submit a support request.'))
    }
    await setupCLI()
    setupLiqCore()
    await setupLiqCompletion()
    return
  }

  let settings
  try {
    settings = readFJSON(fsPath.join(LIQ_HOME, 'local-settings.yaml'))
  }
  catch (e) {
    if (e.code === 'ENOENT') {
      settings = {}
    }
    else {
      throw e
    }
  }

  let response = await callEndpoint(args)

  const isQnA = !!response.headers.get('X-Question-and-Answer')

  if (isQnA) {
    const qnaBundles = await response.json()
    const answerBundles = []
    let sendBundle = false
    for (const interrogationBundle of qnaBundles) {
      const questioner = new Questioner({ interrogationBundle, initialParameters : interrogationBundle.env })
      const { title, key } = interrogationBundle

      if (title !== undefined) {
        process.stdout.write(formatTerminalText(`<h1>${title}<rst>\n\n`))
      }

      await questioner.question()
      const results = questioner.results

      const bundleResults = []
      const bundle = { results : bundleResults }
      if (key !== undefined) bundle.key = key // we do this to save the characters of sending an undefined key

      results.reduce((acc, r) => {
        const { handling, parameter, paramType, value } = r
        if (handling === 'parameter') {
          addArg({ args, parameter, paramType, value })
        }
        else if (handling === 'keyedParameter') { // TODO: this isn't supported in the stack yet, but makes sense
          addArg({ args, parameter : `${key}:${parameter}`, paramType, value })
        }
        else if (handling === undefined || handling === 'bundle') {
          acc.push(r)
          sendBundle = true
        }
        return acc
      }, bundleResults)

      answerBundles.push(bundle) // best practice is to send a key and access result values using the key, but we
      // always push a result bundle for each question bundle to facilicate position-based processing
    }

    // if the answer bundle is truly empty, then we don't send it as the receiver probably doesn't support 'answers'
    // parameter
    if (sendBundle === true) {
      addArg({ args, parameter : 'answers', paramType : 'string', value : JSON.stringify(answerBundles) })
    }

    process.stdout.write('\nRe-sending request with answers...\n')
    response = await (callEndpoint(args))
  }

  const contentType = response.headers.get('Content-Type')
  const disposition = response.headers.get('Content-Disposition')
  // const status = response.status

  if (disposition?.startsWith('attachment')) { // save the file
    let outputFileName = 'output'
    const [, fileNameBit] = disposition.split(/;\s*/)
    if (fileNameBit.startsWith('filename=')) {
      const [, rawFileName] = fileNameBit.split(/=\s*/)
      outputFileName = fsPath.basename(rawFileName.replace(/^['"]/, '').replace(/['"]$/, ''))
    }

    await fs.writeFile(outputFileName, (await response.blob()).stream())
    console.log(`Saved '${contentType}' file '${outputFileName}'.`)
  }
  else { // output to screen
    /* if (status >= 400) { // TODO: make optional?
      const errorSource = status < 500 ? 'Client' : 'Server'
      console.error(formatTerminalText(`<error>${errorSource} error ${status}: ${response.statusText}<rst>`))
    } */
    if (contentType.startsWith('application/json')) {
      console.log(JSON.stringify(await response.json(), null, '  '))
    }
    else {
      const terminalOpts = settings?.TERMINAL || {}
      const text = await response.text()
      const wrappedText = wrap(text, { width : 80, ignoreTags : true, smartIndent : true })
      console.log(formatTerminalText(wrappedText, terminalOpts))
    }
  }
})()

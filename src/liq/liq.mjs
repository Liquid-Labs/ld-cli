import * as fs from 'node:fs/promises'
import * as fsPath from 'node:path'

import { readFJSON } from '@liquid-labs/federated-json'
import { formatTerminalText } from '@liquid-labs/terminal-text'
import { Questioner } from '@liquid-labs/question-and-answer'

import { processCommand } from './lib'

const args = process.argv.slice(2)

const callEndpoint = async(args, bundle) => {
  const { fetchOpts, url } = await processCommand(args)

  fetchOpts.headers['X-CWD'] = fsPath.resolve(process.cwd()) // TODO: walk down until we find 'package.json'

  return await fetch(url, fetchOpts)
}

const addArg = ({ args, parameter, paramType, value }) => {
  if (!args.includes('--')) { args.push('--') }
  if (paramType?.match(/bool(?:ean)?/i)) {
    if (value === true) {
      args.push(parameter)
    }
  }
  else if (paramType === 'string' || paramType === undefined) {
    // will escape with single '\', but we have to escape the escape
    //                                              v       v
    args.push(`${parameter}='${value.replaceAll(/(['\\])/g, '\\$1')}'`)
  }
  else {
    args.push(parameter + '=' + value)
  }
}

(async() => {
  let settings
  try {
    settings = readFJSON(fsPath.join(process.env.HOME, '.liq', 'local-settings.yaml'))
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
    const questioner = new Questioner()
    questioner.interogationBundle = await response.json()

    await questioner.question()
    const results = questioner.results
    const bundle = {}

    for (const { handling, parameter, paramType, value } of results) {
      if (handling === 'parameter') {
        addArg({ args, parameter, paramType, value })
      }
      else if (handling === 'bundle') {
        bundle[parameter] = value
      }
    }

    if (Object.keys(bundle).length > 0) {
      addArg({ args, parameter : 'answers', paramType : 'string', value : JSON.stringify(bundle) })
    }

    response = await (callEndpoint(args))

    process.stdout.write('\nRe-sending request with answers...')
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
      console.log(formatTerminalText(await response.text(), terminalOpts))
    }
  }
})()

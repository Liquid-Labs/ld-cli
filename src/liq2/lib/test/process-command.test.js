/* global describe expect test */

import { processCommand } from '../process-command'
import { PORT, PROTOCOL, SERVER } from '../constants'

describe('processCommand', () => {
  test.each([
    [ [], '/' ],
    [ [ 'foo' ], '/foo' ],
    [ [ 'foo',  'bar' ], '/foo/bar' ],
    [ [ 'foo bar', 'baz' ], '/foo%20bar/baz' ]
  ])("command '%s' yields path '%s'", (command, expectedPath) => {
    const { path } = processCommand(command)
    expect(path).toEqual(expectedPath)
  })
  
  test('processes leading method', () => {
    const { method, path } = processCommand([ 'POST', 'foo', 'bar' ])
    expect(method).toBe('post')
    expect(path).toBe('/foo/bar')
  })
  
  test.each([
    [ [ 'foo=1' ], [[ 'foo', '1' ]]],
    [ [ 'bar=hey there' ], [['bar', 'hey there' ]]],
    [ [ 'baz' ], [[ 'baz', 'true' ]]],
    [ [ 'foo=1', 'baz'], [['foo', '1'], ['baz', 'true' ]]]
  ])("parameter '%s' yields '%p'", (param, expectedData) => {
    const { data } = processCommand(['foo', '--', ...param])
    expect(data).toEqual(expectedData)
  })
  
  test.each([
    [ 'create', 'post' ],
    [ 'delete', 'delete' ],
    [ 'options', 'options' ],
    [ 'update', 'put' ],
    [ 'quit', 'unbind' ],
    [ 'foo', 'get' ]
  ])("path 'foo/%s' implies method '%s'", (pathBit, expectedMethod) => {
    const { method } = processCommand([ 'foo', pathBit ])
    expect(method).toBe(expectedMethod)
  })
  
  test.each([
    [ [ 'foo', 'create', '--', 'bar=1' ], '/foo/create' ],
    [ [ 'foo', 'bar', '--', 'baz=1' ], '/foo/bar?baz=1'],
    [ [ 'foo', 'bar', '--', 'baz=1', 'bobo' ], '/foo/bar?baz=1&bobo=true']
  ])(`command '%p' yields url '${PROTOCOL}://${SERVER}:${PORT}%s'`, (commands, expectedPath) => {
    const { url } = processCommand(commands)
    expect(url).toBe(`${PROTOCOL}://${SERVER}:${PORT}${expectedPath}`)
  })
})

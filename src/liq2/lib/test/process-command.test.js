/* global describe expect test */

import { processCommand } from '../process-command'

describe('processCommand', () => {
  test.each([
    [ [], '/' ],
    [ [ 'foo' ], '/foo' ],
    [ [ 'foo',  'bar' ], '/foo/bar' ],
    [ [ 'foo bar', 'baz' ], '/foo%20bar/baz' ]
  ])("command '%s' yields path '%s'", (command, expectedPath) => {
    const [ , path, ] = processCommand(command)
    expect(path).toEqual(expectedPath)
  })
  
  test('processes leading method', () => {
    const [ method, path, ] = processCommand([ 'POST', 'foo', 'bar' ])
    expect(method).toBe('post')
    expect(path).toBe('/foo/bar')
  })
  
  test.each([
    [ 'foo=1', [ 'foo', '1' ]],
    [ 'bar=hey there', [ 'bar', 'hey%20there' ]],
    [ 'baz', [ 'baz', 'true' ]]
  ])("parameter '%s' yields '%p'", (param, expectedData) => {
    const [ , , data ] = processCommand(['foo', '--', param])
    expect(data).toEqual([ expectedData ])
  })
  
  test.each([
    [ 'create', 'post' ],
    [ 'delete', 'delete' ],
    [ 'options', 'options' ],
    [ 'update', 'put' ],
    [ 'quit', 'unbind' ],
    [ 'foo', 'get' ]
  ])("path 'foo/%s' implies method '%s'", (pathBit, expectedMethod) => {
    const [ method, , ] = processCommand([ 'foo', pathBit ])
    expect(method).toBe(expectedMethod)
  })
})

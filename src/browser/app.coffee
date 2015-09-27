# Copyright 2015 SASAKI, Shunsuke. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

app = require 'app'
BrowserWindow = require 'browser-window'
Menu = require 'menu'
ipc = require 'ipc'
uuidv4 = require 'uuid-v4'
fs = require 'fs'

app.on 'window-all-closed', ->
  app.quit()

openBrowser = (packet) ->
  win = new BrowserWindow {
    width: packet.width
    height: packet.height
    # 'web-preferences': {'web-security': false}
  }
  win.loadUrl "file://#{__dirname}/../renderer/index.html"
  win.webContents.on 'did-finish-load', =>
    win.webContents.send 'open', packet
  win

windows = {}
filename = "#{app.getPath('userData')}/application.json"

try
  json = fs.readFileSync(filename)
  data = JSON.parse(json)
catch e
  if e.code != 'ENOENT'
    console.dir err

  data = {}
  data.width = 800
  data.height = 600
  data.opened = [
    {
      uuid: uuidv4()
      width: 800
      height: 600
    }
  ]

  fs.writeFile filename, JSON.stringify(data), (err) =>
    console.dir err

global.width = data.width
global.height = data.height

app.on 'ready', ->
  for packet in data.opened
    windows[packet.uuid] = openBrowser(packet)
    windows[packet.uuid].on 'closed', =>
      windows[packet.uuid] = null

ipc.on 'hoge', (arg, ev) ->
  console.log arg


app       = require('electron').app
fs        = require 'fs-plus'
Tray      = require('electron').Tray
Menu      = require('electron').Menu
newWindow = require './window'

class TrayIcon

  constructor: () ->
    appPath = fs.realpathSync "#{__dirname}/.."
    iconPath = "#{appPath}/images/icon@2x.png"
    @tray = new Tray iconPath
    @menu = Menu.buildFromTemplate [
      {
        label: 'Open Environment',
        click: () ->
          newWindow()
      },
      {
        type: 'separator'
      },
      {
        label: 'Quit Vessel',
        accelerator: 'Command+Q',
        click: () ->
          app.quit()
      }
    ]
    @tray.setToolTip 'Vessel'
    @tray.setContextMenu @menu


module.exports = TrayIcon

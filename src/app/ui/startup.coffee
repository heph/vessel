# Perform startup actions

BrowserWindow = require('electron').BrowserWindow
exec          = require('child_process').exec
fs            = require 'fs-plus'
ipc           = require('electron').ipcMain
semver        = require 'semver'
yaml          = require 'js-yaml'

class Startup
  console.log('called class Startup')

  minVer: '1.6.0'
  url: 'https://github-enterprise.colo.lair/gavinr/vessel-manifest.git'

  constructor: ->
    console.log('called constructor')
    @configDir = "#{fs.getHomeDirectory()}/.vessel"
    @manifestDir = "#{@configDir}/manifest"
    @window = null

  initialize: (callback) ->
    console.log('called initialize')
    @onReady = callback

    if not @_hasConfigDir()
      @_makeConfigDir()

    # Ensure that Vagrant is 1.6.0 or higher
    @_checkVagrantVersion(callback)

  _checkVagrantVersion: (callback) ->
    console.log('called _checkVagrantVersion')
    command = "vagrant --version"
    exec command, (err, stdout, stderr) =>
      if err
        @_onVagrantCheckError 'I could not find the Vagrant application. ' +
                              'Please ensure that Vagrant is installed and ' +
                              'is in the global PATH.'
      else
        version = stdout.split(' ')[1]
        if semver.gte version, @minVer
          @_onVagrantCheckOk(callback)
        else
          @_onVagrantCheckError 'The Vagrant version I found is not ' +
                                'supported. Version ' + version +
                                ' was found but ' + @minVer +
                                ' or greater is required.'

  _onVagrantCheckError: (message) ->
    console.log('called _onVagrantCheckError')
    @window = new BrowserWindow {
      width: 600
      height: 290
      resizable: false
      title: "Vessel Startup Error"
      show: true
    }
    @window.loadURL "file://#{__dirname}/../startup/error.html##{message}"
    @window.on 'closed', () =>
      @window = null

  _onVagrantCheckOk: (callback) ->
    console.log('called _onVagrantCheckOk')
    # Ensure that there is a global manifest
    if not @_hasManifestDir()
      @_createPromptWindow()
    else
      @_gitPullManifestRepo(callback)

  _hasConfigDir: ->
    console.log('called _hasConfigDir')
    fs.existsSync @configDir

  _hasManifestDir: ->
    console.log('called _hasManifestDir')
    fs.existsSync @manifestDir

  _makeConfigDir: ->
    console.log('called _makeConfigDir')
    fs.mkdir @configDir, '0755'

  _gitCloneManifestRepo: (callback) ->
    console.log('called _gitCloneManifestRepo')
    command = "git clone #{@url} #{@manifestDir}"
    exec command, (err, stdout, stderr) =>
      console.log stdout
      console.log stderr
      console.log err
      @onReady()
      @onReady = null

  _gitPullManifestRepo: (callback) ->
    console.log('called _gitPullManifestRepo')
    command = "cd  #{@manifestDir} && git pull origin master"
    exec command, (err, stdout, stderr) ->
      console.log stdout
      console.log stderr
      console.log err
      callback()

  _createPromptWindow: ->
    console.log 'called _createPromptWindow'
    ipc.on 'setURL', (event, url) =>
      @url = url
      @window.close()
      @_gitCloneManifestRepo()

    @window = new BrowserWindow {
      width: 600
      height: 330
      resizable: false
      title: "Vessel Setup"
      show: true
    }

    console.log('attempting to load url: '
      +"file://#{__dirname}/../startup/index.html")
    @window.loadURL "file://#{__dirname}/../startup/index.html"

    @window.on 'closed', () =>
      @window = null

module.exports = Startup

uuidv4 = require 'uuid-v4'
msgpack = require 'msgpack-lite'
remote = require 'remote'
app = remote.require 'app'
fs = require 'fs'
ipc = require 'ipc'

class WritingViewModel
  constructor: (episodeModel) ->
    @html = """
    <div>
      <div data-bind="text: title"></div>
      <div data-bind="command: changeNovel">小説設定</div>
    </div>
    <div data-bind="command: changeNarou">
      なろう詳細設定
    </div>
    <div data-bind="command: changeEpisode">
      エピソード設定
    </div>
    <div>
      <input data-bind="textInput: @subtitle">
    </div>
    <textarea class="max-height" data-bind="textInput: @text">
    </textarea>
    """
    @text = episodeModel.text
    @subtitle = episodeModel.subtitle
    @title = episodeModel.novelModel.title
    @changeNovel = wx.command =>
      episodeModel.novelModel.changeNovel()
    @changeNarou = wx.command =>
      episodeModel.novelModel.changeNarou()
    @changeEpisode = wx.command =>
      episodeModel.novelModel.changeEpisode(episodeModel)

class NarouViewModel
  constructor: (novelModel) ->
    @html = """
    <div data-bind="command: changeNovel">
      <div data-bind="text: title"></div>
    </div>
    <div data-bind="foreach: @completedParam">
      <input type="radio" name="radio-group-1" data-bind="value: value, selectedValue: @parent.isCompleted, attr: { id: 'radio-group-1 -' + $index }">
      <label data-bind="text: text, attr: {for: 'radio-group-1 -' + $index}"></label>
    </div>
    <div data-bind="foreach: @xGenreParam">
      <input type="radio" name="radio-group-2" data-bind="value: value, selectedValue: @parent.xGenre, attr: { id: 'radio-group-2 -' + $index }">
      <label data-bind="text: text, attr: {for: 'radio-group-2 -' + $index}"></label>
    </div>
    <div>
      <input data-bind="textInput: @keywords">
    </div>
    <div>
      <input type="checkbox" data-bind="checked: @warnR15">[R15]
      <input type="checkbox" data-bind="checked: @warnBoys">[ボーイズラブ]
      <input type="checkbox" data-bind="checked: @warnGirls">[ガールズラブ]
      <input type="checkbox" data-bind="checked: @warnCruelly">[残酷な描写あり]
    </div>
    <div>
      <input type="checkbox" data-bind="checked: @exclude">除外設定
    </div>
    """

    @title = novelModel.title
    @summary = novelModel.summary

    @isCompleted = wx.property ''
    @completedParam = wx.list([
      {text: '完結済み', value: true}
      {text: '連載中', value: false}
    ])
    @xGenreParam = wx.list([
      {text: '男性向け', value: 'men'}
      {text: '女性向け', value: 'women'}
      {text: 'ボーイズラブ', value: 'boys'}
    ])
    @xGenre = wx.property ''

    @keywords = wx.property ''

    @warnR15 = wx.property false
    @warnGirls = wx.property false
    @warnBoys = wx.property false
    @warnCruelly = wx.property false

    @exclude = wx.property false

    @authorOverride = wx.property ''

    @changeWriting = wx.command =>
      novelModel.changeWriting()
    @changeNovel = wx.command =>
      novelModel.changeNovel()

class NovelViewModel
  constructor: (novelModel) ->
    @html = """
    <div>
      タイトル:
      <input data-bind="textInput: @title" placeholder="タイトル">
    </div>
    <div>
      あらすじ:
      <textarea class="summary" data-bind="textInput: @summary" placeholder="あらすじ"></textarea>
    </div>
    <div data-bind="command: changeNarou">
      なろう詳細設定
    </div>
    <div data-bind="command: newEpisode">
      新規執筆
    </div>
    <div data-bind="foreach: episodes">
      <div data-bind="text: subtitle, command: {command: $parent.changeEpisode, parameter: $data}">
    </div>
    """
    @title = novelModel.title
    @summary = novelModel.summary
    @episodes = novelModel.episodes

    @changeNarou = wx.command =>
      novelModel.changeNarou()

    @newEpisode = wx.command =>
      novelModel.newEpisode()

    @changeEpisode = wx.command (episodeModel) =>
      novelModel.changeEpisode(episodeModel)

class EpisodeViewModel
  constructor: (episodeModel) ->
    @html = """
    <div data-bind="command: changeNovel">
      <div data-bind="text: title"></div>
      小説設定
    </div>
    <div data-bind="command: changeNarou">
      なろう詳細設定
    </div>
    <div>
      <input data-bind="textInput: @subtitle">
    </div>
    <div>
      <textarea data-bind="textInput: @preScript"></textarea>
    </div>
    <div data-bind="command: writing">
      本文執筆
      <div data-bind="text: text"></div>
    </div>
    <div>
      <textarea data-bind="textInput: @postScript"></textarea>
    </div>
    """

    @title = episodeModel.novelModel.title
    @subtitle = episodeModel.subtitle
    @preScript = episodeModel.preScript
    @text = episodeModel.text
    @postScript = episodeModel.postScript
    @writing = wx.command =>
      episodeModel.novelModel.changeWriting(episodeModel)
    @changeNovel = wx.command =>
      episodeModel.novelModel.changeNovel()
    @changeNarou = wx.command =>
      episodeModel.novelModel.changeNarou()

class EpisodeModel
  @unmarshal: (obj, novelModel) ->
    episodeModel = new EpisodeModel(novelModel)
    episodeModel.subtitle(obj.subtitle)
    episodeModel.text(obj.text)
    episodeModel.preScript(obj.pre_script)
    episodeModel.postScript(obj.post_script)
    episodeModel.originalSubtitle(obj.subtitle)
    episodeModel.originalText(obj.text)
    episodeModel.originalPreScript(obj.pre_script)
    episodeModel.originalPostScript(obj.post_script)
    episodeModel

  constructor: (novelModel) ->
    @novelModel = novelModel

    @subtitle = wx.property ''
    @text = wx.property ''
    @preScript = wx.property ''
    @postScript = wx.property ''

    @originalSubtitle = wx.property ''
    @originalText = wx.property ''
    @originalPreScript = wx.property ''
    @originalPostScript = wx.property ''

    # GC されないために
    @changed = wx.whenAny @subtitle, @text, @preScript, @postScript, @originalSubtitle, @originalText, @originalPreScript, @originalPostScript, (subtitle, text, preScript, postScript, originalSubtitle, originalText, originalPreScript, originalPostScript) =>

      if subtitle != originalSubtitle || text != originalText || preScript != originalPreScript || postScript != originalPostScript
        @novelModel.update()

        @originalSubtitle(@subtitle())
        @originalText(@text())
        @originalPreScript(@preScript())
        @originalPostScript(@postScript())

      'changed'
    .toProperty()

    @episodeViewModel = new EpisodeViewModel(@)
    @writingViewModel = new WritingViewModel(@)

  marshal: (clock) ->
    {
      clock: clock
      subtitle: @subtitle()
      text: @text()
      pre_script: @preScript()
      post_script: @postScript()
    }

class NovelModel
  @unmarshal: (obj) ->
    novelModel = new NovelModel()
    novelModel.uuid = obj.uuid
    novelModel.clock = obj.clock
    novelModel.title(obj.title)
    novelModel.summary(obj.summary)
    novelModel.originalTitle(obj.title)
    novelModel.originalSummary(obj.summary)

    for episodeObj in obj.episodes
      novelModel.episodes.push EpisodeModel.unmarshal(episodeObj, novelModel)
    novelModel

  constructor: (uuid) ->
    @changeSubject = new Rx.Subject()
    @changeObservable = @changeSubject.publish()
    @changeObservable.connect()

    @uuid = uuid

    @title = wx.property ''
    @summary = wx.property ''

    @originalTitle = wx.property ''
    @originalSummary = wx.property ''

    # GC されないために
    @chaned = wx.whenAny @title, @summary, @originalTitle, @originalSummary, (title, summary, originalTitle, originalSummary) =>

      if title != originalTitle || summary != originalSummary
        @update.call @

        @originalTitle(@title())
        @originalSummary(@summary())

      'changed'
    .toProperty()

    @vm = wx.list()
    @episodes = wx.list()

    @novelViewModel = new NovelViewModel(@)
    @narouViewModel = new NarouViewModel(@)

    @changeNovel.call @
    @clock = 0

  changeNarou: ->
    @vm.clear()
    @vm.push @narouViewModel

  changeNovel: ->
    @vm.clear()
    @vm.push @novelViewModel

  newEpisode: ->
    episodeModel = new EpisodeModel(@)
    @episodes.push episodeModel
    @vm.clear()
    @vm.push episodeModel.episodeViewModel

  changeEpisode: (episodeModel) ->
    @vm.clear()
    @vm.push episodeModel.episodeViewModel

  changeWriting: (episodeModel) ->
    @vm.clear()
    @vm.push episodeModel.writingViewModel

  update: ->
    @changeSubject.onNext(@marshal.call(@))

  marshal: ->
    @clock = (new Date()).getTime()
    episodes = []
    @episodes.forEach (value, index, arr) =>
      episodes.push value.marshal(@clock)

    {
      uuid: @uuid
      clock: @clock
      title: @title()
      summary: @summary()
      episodes: episodes
    }

class MainViewModel
  _loadNovel = (uuid) ->
    re = new RegExp("^#{uuid}-([0-9]+).msgpack$")
    files = fs.readdirSync app.getPath('userData')
    clock = '0'
    for filename in files
      match = re.exec(filename)
      continue unless match

      if Number(match[1]) > Number(clock)
        clock = match[1]

    if clock == '0'
      null
    else
      filename = "#{app.getPath('userData')}/#{uuid}-#{clock}.msgpack"
      fs.readFileSync filename

  _saveNovel = (obj) ->
    filename = "#{app.getPath('userData')}/#{obj.uuid}-#{obj.clock}.msgpack"

    fs.writeFile filename, msgpack.encode(obj), (err) =>
      if err
        console.error err
        console.dir err
      else
        console.log "saved: #{filename}"

  constructor: ->
    @panes = wx.list()

  openNovel: (uuid) ->
    if @panes.length() > 0
      console.error "FATAL すでに開かれてます"

    packed = _loadNovel uuid

    if packed
      novelModel = NovelModel.unmarshal(msgpack.decode(packed))
    else
      novelModel = new NovelModel(uuid)

    novelModel.changeObservable.buffer(=> Rx.Observable.timer(5000)).filter((objs) => objs.length > 0).subscribe (objs) =>
      obj = objs.pop()

      _saveNovel obj

    @panes.push novelModel

  loadNovel: (uuid) ->


mainViewModel = new MainViewModel()

ipc.on 'open', (packet) =>
  mainViewModel.openNovel(packet.uuid)

wx.applyBindings(mainViewModel)


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
  constructor: (novelModel, conf) ->
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
  constructor: (novelModel, conf) ->
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
    console.dir @episodes

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
  constructor: (novelModel) ->
    @novelModel = novelModel
    @subtitle = wx.property ''
    @text = wx.property ''
    @preScript = wx.property ''
    @postScript = wx.property ''

    @episodeViewModel = new EpisodeViewModel(@)
    @writingViewModel = new WritingViewModel(@)

class NovelModel
  constructor: (conf) ->
    @title = wx.property ''
    @summary = wx.property ''
    @vm = wx.list()
    @episodes = wx.list()

    @novelViewModel = new NovelViewModel(@, conf)
    @narouViewModel = new NarouViewModel(@, conf)

    @changeNovel.call @

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

  toJson: ->
    JSON.stringify
      title: @title()
      summary: @summary()


class MainViewModel
  constructor: ->
    novelModel = new NovelModel {}
    @panes = wx.list()
    @panes.push novelModel
    @panes.push {vm: {html: wx.property "<div>fuga</div>"}}

mainViewModel = new MainViewModel()

wx.applyBindings(mainViewModel)

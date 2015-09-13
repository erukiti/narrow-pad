class WritingViewModel
  constructor: (novelModel, conf) ->
    @html = """
    <div>
      <input data-bind="textInput: @subtitle">
    </div>
    <textarea class="max-height" data-bind="textInput: @text"></textarea>
    """
    @text = wx.property ''
    @subtitle = wx.property ''

class NarouViewModel
  constructor: (novelModel, conf) ->
    @html = """
    <div data-bind="text: title">
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

    @author = wx.property ''

    @changeWriting = wx.command () =>
      novelModel.changeWriting()

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
    <div>
    </div>
    <div>
    </div>
    """
    @title = novelModel.title
    @summary = novelModel.summary
    @changeNarou = wx.command =>
      novelModel.changeNarou()

class NovelModel
  constructor: (conf) ->
    @title = wx.property ''
    @summary = wx.property ''

    @novelViewModel = new NovelViewModel(@, conf)
    @narouViewModel = new NarouViewModel(@, conf)
    @vm = wx.list()

    @changeNovel.call @

  changeNarou: ->
    @vm.clear()
    @vm.push @narouViewModel

  changeNovel: ->
    @vm.clear()
    @vm.push @novelViewModel

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

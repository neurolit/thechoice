PREFIX = """
_challenge = (context) ->
  _usercode.apply(context)

_respond = (successes, total) ->
  { successes: successes, total: total }
"""

class Controls

  constructor: (@dialog) ->
    @index = 0
    @card = null

    @button = $('.submit')
    @setupEditor()
    @fetchCards()

  setupEditor: ->
    @editor = ace.edit("editor")
    @editor.setTheme("ace/theme/tomorrow_night")
    @editor.setFontSize(16)
    @editor.renderer.setShowGutter(false)
    @editor.renderer.updateCursor("url('cursor-caret.png')")
    @editor.getSession().setMode("ace/mode/coffee")

  fetchCards: ->
    jsyaml = window.jsyaml
    $.get 'cards.yml', (data) =>
      @cards = jsyaml.load(data)
      console.log "Cards loaded!"
      @showCard()
      @setupEvents()

  nextCard: ->
    @index += 1
    @showCard()

  showCard: ->
    @card = @cards[@index]
    @say(@card.text)

    switch @card.type
      when 'clear'
        @dialog.clear()
        @editor.setValue('')
        @nextCard()
      when 'code'
        @editor.focus()

  setupEvents: ->
    @button.click =>
      @submit()

  submit: ->
    switch @card.type
      when 'text'
        @nextCard()
      when 'code'
        @submitCode()

  submitCode: ->
    console.log 'submitCode!'
    input = @editor.getValue().trim()
    if input == ''
      @say 'Well? Type something!'
      return

    input = input.split("\n").map((x) -> '  ' + x).join("\n")
    code = PREFIX + "\n_usercode = ->\n" + input + "\n" + @card.code + "\nreturn _condition()"
    console.log { code: code }

    try
      js = CoffeeScript.compile(code)
      result = eval(js)

      if result.successes == result.total
        @nextCard()
      else if result.total > 1
        @say "Your answer only works #{result.successes / result.total * 100.0}% of the time. Try again."
      else
        @say "Your answer is unsatisfactory. Try again."
    catch error
      @say error.message + " - Try again."
    finally
      @editor.focus()

  say: (msg) ->
    @dialog.push("Man", msg)
        

class Dialog

  constructor: ->
    @element = $('.dialog')

  push: (who, what) ->
    line = $("<p><span class='character'>#{who}: </span>#{what}</p>")
    line.hide()
    @element.append(line)
    line.fadeIn()
    @element.scrollTop(@element[0].scrollHeight)
    speak(what)

  clear: ->
    @element.children().fadeOut().remove()

$ ->
  dialog = new Dialog()
  controls = new Controls(dialog)


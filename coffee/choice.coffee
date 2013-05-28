class Controls

  constructor: (@dialog) ->
    @index = 0
    @card = null
    @tries = 0
    @hintNumber = 0

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
      @setupEvents()

      if window.location.hash == ""
        @showCard()
      else
        code = window.location.hash.substring(1)
        # load cheat
        for card, i in @cards
          if card.type == 'save' && card.code == code
            @index = i
            @showCard()
            return

  nextCard: ->
    @tries = 0
    @hintNumber = 0
    @index += 1
    @showCard()

  showCard: ->
    @card = @cards[@index]
    if @card.type == 'code'
      $('.scene').addClass('code')
    else
      $('.scene').removeClass('code')

    switch @card.type
      when 'clear'
        @dialog.clear()
        @editor.setValue('')
        @nextCard()
      when 'code'
        @put @card.text
        @editor.focus()
      when 'text'
        @say @card.text
      when 'save'
        @nextCard()

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
      @fail()
      return

    input = input.split("\n").map((x) -> '  ' + x).join("\n")
    code = BASECODE + "\n_usercode = ->\n" + input + "\n\n" + @card.code + "\nreturn _condition()"
    console.log code

    try
      js = CoffeeScript.compile(code)
      result = eval(js)

      if result.message
        @say result.message
        if result.advance == true
          @nextCard()
        else
          @fail()
        return

      if result.successes == result.total
        @nextCard()
      else if result.total > 1
        if result.successes == 0
          @say "Your answer never works. Try again."
          @fail()
        else
          @say "Your answer only works #{result.successes / result.total * 100.0}% of the time. Try again."
          @fail()
      else
        @say "Your answer is unsatisfactory. Try again."
        @fail()
    catch error
      @say error.message + " - Try again."
      @fail()
    finally
      @editor.focus()

  fail: ->
    @tries++
    if @tries >= (@hintNumber + 1) * 3
      @showHint()

  showHint: ->
    @hintNumber++
    if @card.hints && @card.hints.length >= @hintNumber
      @say "Here's a hint. #{@card.hints[@hintNumber - 1]}"

  say: (msg) ->
    @dialog.push("Man", msg)

  put: (msg) ->
    @dialog.instruct(msg)
        

class Dialog

  constructor: ->
    @element = $('.dialog')

    @sound = true
    if /\?nosound/.test window.location.search
      @sound = false

  push: (who, what) ->
    @speak what
    line = $("<p><span class='character'>#{who}: </span>#{what}</p>")
    @_append(line)

  instruct: (what) ->
    @speak what
    line = $("<p class='instructions'>#{what}</p>")
    @_append(line)

  speak: (what) ->
    if @sound
      speak(what, { amplitude: 150, pitch: 10, speed: 190 })

  _append: (line) ->
    line.hide()
    @element.append(line)
    line.fadeIn()
    @element.scrollTop(@element[0].scrollHeight)

  clear: ->
    @element.children().fadeOut().remove()

$ ->
  dialog = new Dialog()
  controls = new Controls(dialog)

BASECODE = """
_challenge = (context) ->
  _usercode.apply(context)

_respond = (successes, total) ->
  { successes: successes, total: total }

_retort = (message) ->
  { message: message }

class SimpleQuestion

  constructor: (@definition) ->
    @correct = false
    @answered = false
    @smartass = false

  answer: (raw) ->
    text = raw.toLowerCase().trim()

    @answered = true

    if @definition.correct.indexOf(text) != -1
      @correct = true
      return

    if @definition.smartass.indexOf(text) != -1
      @smartass = true
      return
    
  react: ->
    if @answered
      if @correct
        _respond 1, 1
      else if @smartass
        _retort 'We do not find this amusing. You are immediately required to stop fooling around.'
      else
        _retort 'This is not the correct answer.'
    else
      _retort 'You did not answer anything.'

"""


`
/**
 * Well hello there!
 *
 * If you're reading this, you're either trying to cheat,
 * in which case, shame on you - or you're trying to fork this
 * project to make your own questions in which case, welcome!
 *
 * Just make sure your work is unique though. M'kay?
 */
`

class Controls

  constructor: (@dialog) ->
    @index = 0
    @card = null
    @tries = 0
    @hintNumber = 0

    @setupEditor()
    @fetchCards()

    @prelude = ""

  setupEditor: ->
    @editor = ace.edit("editor")
    @editor.setTheme("ace/theme/tomorrow_night")
    @editor.setFontSize(16)
    @editor.renderer.updateCursor("url('cursor-caret.png')")
    @editor.getSession().setMode("ace/mode/coffee")
    @editor.commands.addCommand {
      name: 'submit'
      bindKey: {win: 'Ctrl-Enter',  mac: 'Command-Enter'}
      exec: (editor) => @submit()
      readOnly: true
    }

  fetchCards: ->
    jsyaml = window.jsyaml
    $.get 'cards.yml?v1', (data) =>
      @cards = jsyaml.load(data)
      @setupEvents()

      if window.location.hash == ""
        @showCard()
      else
        code = window.location.hash.substring(1)
        # load cheat
        @button.hide()
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
        @say @prelude + @card.text
        @prelude = ""
        if @card.sample
          @editor.setValue(@card.sample)
      when 'nobutton'
          @button.hide()
          @nextCard()
      when 'save'
        @nextCard()
      when 'end'
        text = """
        That's it for now. Tell me what you think about it
        by <a href="https://twitter.com/intent/tweet?text=@nddrylliog I just played The Choice and here's what I think: " target="_blank">sending me a tweet.</a>
        Thanks for playing!
        """
        @silent text

  setupEvents: ->
    @button = $('.submit')
    @button.click =>
      @submit()

  submit: ->
    switch @card.type
      when 'text'
        @nextCard()
      when 'code'
        if @card.empty == true
          @nextCard()
        else
          @submitCode()

  submitCode: ->
    input = @editor.getValue().trim()
    if input == ''
      @say 'Well? Type something!'
      @fail()
      return

    input = input.split("\n").map((x) -> '  ' + x).join("\n")
    code = BASECODE + "\n_usercode = ->\n" + input + "\n\n" + @card.code + "\nreturn _condition()"

    try
      js = CoffeeScript.compile(code)
      result = eval(js)

      if result.message
        if result.advance == true
          @prelude = result.message + ' '
          @nextCard()
        else
          @say result.message
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
    if @tries >= (@hintNumber + 1) * 5
      @showHint()

  showHint: ->
    @hintNumber++
    if @card.hints && @card.hints.length >= @hintNumber
      @silent "Hint: #{@card.hints[@hintNumber - 1]}"

  say: (msg) ->
    @dialog.push("EEM", msg)

  put: (msg) ->
    @dialog.instruct(msg)

  silent: (msg) ->
    @dialog.silent(msg)
        

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

  silent: (what) ->
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

class Showstopper extends Error
  constructor: (@message) ->

class Log
  constructor: ->
    @entries = []
    @failed = false
    @succeded = false

  append: (entry) ->
    @entries.push entry

  fail: ->
    @failed = true
    @entries.push 'You failed.'
    throw new Showstopper('fail')

  succeed: ->
    @succeeded = true
    @entries.push 'You succeeded.'
    throw new Showstopper('success')

  run: (code) ->
    try
      code()
    catch e
      if e instanceof Showstopper
        return @summary()
      else
        # re-throw!!!!!!!
        throw e

    # No showstopper, we probably lost, but we still want to
    # know what happened.
    @summary()

  successful: ->
    if @failed
      return false
    unless @succeeded
      return false
    true

  summary: ->
    message = @entries.join(" ")
    if @failed
      {
        message: message + " Try again."
        advance: false
      }
    else if !@succeeded
      {
        message: message + " You did not complete the task. Try again."
        advance: false
      }
    else
      {
        message: message
        advance: true
      }
    
"""


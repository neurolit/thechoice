###
Well hello there!

If you're reading this, you're either trying to cheat,
in which case, shame on you - or you're trying to fork this
project to make your own questions in which case, welcome!

Just make sure your work is unique though. M'kay?
###

class Controls

  constructor: (@dialog) ->
    @index = 0
    @card = null
    @tries = 0
    @hintNumber = 0

    @box = $('.box')
    @box.hide()
    @boxBody = @box.find('.box-body')

    @setupEditor()
    @fetchCards()

    @prelude = ""

  setupEditor: ->
    @editor = ace.edit("editor")
    @editor.setTheme("ace/theme/tomorrow_night")
    @editor.setFontSize(16)
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
    @focus()
    @card = @cards[@index]
    if @card.type == 'code'
      $('.scene').addClass('code')
    else
      $('.scene').removeClass('code')

    switch @card.type
      when 'clear'
        @dialog.clear()
        @fill ''
        @nextCard()
      when 'code'
        @put @card.text
      when 'text'
        @say @prelude + @card.text
        @prelude = ""
        if @card.sample
          @fill @card.sample
      when 'nobutton'
          @button.hide()
          @nextCard()
      when 'save'
        @nextCard()
      when 'end'
        text = """
        To be continued... Tell me what you think about it
        by <a href="https://twitter.com/intent/tweet?text=@nddrylliog I just played The Choice and here's what I think: " target="_blank">sending me a tweet.</a>
        Thanks for playing!
        """
        @silent text

  focus: ->
    @editor.blur()
    @editor.focus()

  fill: (value) ->
    @editor.setValue(value)
    @editor.clearSelection()

  setupEvents: ->
    @button = $('.submit')
    @button.click =>
      @submit()

    $(window).keypress (ev) =>
      if (ev.which == 10) || (ev.which == 13)
        if @hideBox()
          ev.preventDefault()
          return false
      true

  hideBox: ->
    if @box.is(':visible')
      @box.fadeOut()
      true
    else
      false

  showBox: ->
    @box.fadeIn()

  submit: ->
    if @hideBox()
      return

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

    # start with base code
    code = BASECODE

    @card.extensions ||= []
    for ext in @card.extensions
      code += "\n\n" + EXTENSIONS[ext]


    # add player code
    input = input.split("\n").map((x) -> '  ' + x).join("\n")
    code += "\n\n_usercode = ->\n" + input

    # add card custom code
    code += "\n\n" + @card.code + "\nreturn _condition()"

    console.log code

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

      if result.box == true
        if result.advance == true
          @nextCard()
        else
          $list = $('<ul></ul>')
          for e in result.elements
            $elem = $("<li>#{e}</li>")
            $elem.appendTo($list)
          @boxBody.html('')
          $list.appendTo(@boxBody)
          @showBox()
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

BASECODE = '''
_challenge = (context) ->
  _usercode.apply(context)

_respond = (successes, total) ->
  { successes: successes, total: total }

_retort = (message) ->
  { message: message }

_pick = (arr) ->
  arr[Math.floor(Math.random() * (arr.length - 1))]

_randomKey = ->
  key = ""
  key += _pick ['thal', 'domi', 'lake', 'jijo', 'rami', 'zana', 'lojr', 'baso', 'zola']
  key += _pick ['wika', 'bijo', 'noka', 'krei', 'plaz', 'xxuf', 'yowm', 'gaho', 'lipl']
  key

class SimpleQuestion
  constructor: (@definition) ->
    @definition.correct  ||= []
    @definition.wrongdir ||= []
    @definition.smartass ||= []

    @correct = false
    @answered = false
    @smartass = false
    @lastAnswer = ""

  answer: (raw) ->
    text = raw.toLowerCase().trim()
    @lastAnswer = text

    @answered = true

    if @definition.correct.indexOf(text) != -1
      @correct = true
      return

    if @definition.wrongdir.indexOf(text) != -1
      @wrongdir = true
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
      else if @wrongdir
        _retort 'You are looking in all the wrong places.'
      else
        _retort "You answered #{@lastAnswer}. This is not the correct answer."
    else
      _retort 'You did not answer anything.'

class Showstopper extends Error
  constructor: (@message) ->

class Log
  constructor: ->
    @entries = []
    @failed = false
    @succeded = false
    @box = true

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
    if @failed
      @append 'Try again.'
    else if !@succeeded
      @append 'You did not complete the tasks. Try again.'

    if @box
      {
        box: true
        elements: @entries
        advance: @successful()
      }
    else
      message = @entries.join(" ")
      {
        message: message
        advance: @successful()
      }
    
'''

EXTENSIONS = {}

EXTENSIONS.ship = '''
class Stage
  constructor: (@log) ->
    @stations = {}

  getStation: (name) ->
    @stations[name]

class Vehicle
  constructor: (@log, @stage, @station) ->
    @passengers = []

  fly: (stationName) ->
    if @passengers.length == 0
      @log.append "You tried to fly a vehicle with no passengers."
      @log.append "It got lost in the void of space."
      @log.fail()

    dest = @stage.getStation(stationName)
    if dest
      if dest == @station
        @log.append "You tried to fly a vehicle to the same place it already was."
        @log.fail()

      @station = dest
      @unload()
    else
      @log.append "You tried to fly to station #{stationName} which doesn't exist."
      @log.fail()

  unload: ->
    for p in @passengers
      p.unload()
    @passengers = []

class Station
  constructor: (@log, @stage, @name) ->
    @stage.stations[@name] = @
    @crowd = []

  crowdedness: ->
    @crowd.length

  enter: (numan) ->
    @crowd.push(numan)

  exit: (numan) ->
    i = @crowd.indexOf(numan)
    if i != -1
      @crowd.splice(i, 1)

class Numan
  constructor: (@log, @name, @station) ->
    @vehicle = null
    @station.enter(@)
    
  board: (vehicle) ->
    @station.exit(@)
    if @vehicle
      @log.append "You told numan #{@name} to board a vehicle, but he was already boarded."
      @log.fail()

    unless vehicle.station == @station 
      @log.append "You told numan #{@name} to board a vehicle in a different station."
      @log.fail()

    vehicle.passengers.push(@)
    @vehicle = vehicle

  unload: ->
    @station = @vehicle.station
    @station.enter(@)
    @vehicle = null
    @log.append "Numan #{@name} arrived at station #{@station.name}."
'''


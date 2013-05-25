
class Controls

  constructor: (@dialog) ->
    @button = $('.submit')
    @textarea = $('textarea.cli')
    @setupEvents()

  setupEvents: ->
    @button.click =>
      input = @textarea.val()
      input = input.split("\n").map((x) -> '  ' + x).join("\n")
      code = "_thechoice = ->\n" + input + "\nreturn _thechoice()"
      console.log code

      try
        js = CoffeeScript.compile(code)
        result = eval(js)
        if result
          @dialog.push("Man", "Your answer is: #{result} - Are you confident?")
        else
          @dialog.push("Man", "This gives nothing, it's not good.")
      catch error
        @dialog.push("Man", error.message + " - Try again.")
      finally
        @textarea.focus()
        

class Dialog

  constructor: ->
    @element = $('.dialog')

  push: (who, what) ->
    line = $("<p><span class='character'>#{who}: </span>#{what}</p>")
    line.hide()
    @element.append(line)
    line.fadeIn()
    @element.scrollTop(@element[0].scrollHeight)

$ ->
  dialog = new Dialog()
  controls = new Controls(dialog)

  dialog.push("Man", "Welcome, subject #20394. You have been brought here to pass the
    most important test in your life.")
  dialog.push("Man", "If you have understood the instructions, type 'Yes.'")
  dialog.push("Man", "Not 'yes', not 'yes.', 'Yes.'.")
  console.log 'We are live!'



class Dialog

  constructor: ->
    @element = $('.dialog')

  push: (who, what) ->
    @element.append("<p><span class='character'>#{who}: </span>#{what}</p>")
    

$ ->
  dialog = new Dialog()
  dialog.push("Man", "Welcome, subject #20394. You have been brought here to pass the
    most important test in your life.")
  dialog.push("Man", "If you have understood the instructions, type 'Yes.'")
  dialog.push("Man", "Not 'yes', not 'yes.', 'Yes.'.")
  console.log 'We are live!'


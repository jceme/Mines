class EventObject
  
  'use strict'
  
  constructor: ->
    @_eventListeners = {}
  
  
  on: (eventName, listener) ->
    (@_eventListeners[eventName] ?= []).push listener
    @
  
  off: (eventName, listener) ->
    if listener?
      @_eventListeners[eventName] = (@_eventListeners[eventName] ? []).filter (x) -> x isnt listener
    else
      delete @_eventListeners[eventName]
    @
  
  fire: (eventName, data...) ->
    listener.apply null, data for listener in @_eventListeners[eventName] ? []
    @
      




if module?.exports?
  module.exports = EventObject
else
  (-> @)().EventObject = EventObject

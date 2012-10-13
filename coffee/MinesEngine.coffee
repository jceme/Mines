class MinesEngine
  
  'use strict'
  
  randBool = (ratio) -> Math.random() < ratio
  
  
  @UNKNOWN: -1
  @MARKED: -2
  
  constructor: ->
    @eventListeners = {}
  
  createBoard: (width, height, bombRatio) ->
    # Board is 2-dim array, rows in top level, cols per row
    board = (
      (
        {
          #bomb: if col is firstX and row is firstY then off else randBool bombRatio
          mark: MinesEngine.UNKNOWN
        } for col in [0...width]
      ) for row in [0...height]
    )
    
    @totalBombs = remainingNonBombs = startTime = timer = timerId = null
    
    now = -> (new Date()).getTime()
    
    init = (x, y) ->
      @totalBombs = 0
      for row in [0...height] then for col in [0...width]
        board[row][col].bomb = b = if col is x and row is y then off else randBool bombRatio
        @totalBombs++ if b
      
      remainingNonBombs = width * height - @totalBombs
      @fire 'init', @totalBombs
      
      timer = 0
      timerId = setInterval (=> @fire 'timer', ++timer), 1000
      startTime = now()
      
      init = null
    
    finish = (won, x, y, data) ->
      time = (now() - startTime) / 1000
      clearInterval timerId
      @fire 'finished', won, time, x, y, data
      board = null
    
    getCell = (x, y) ->
      throw new Error("Invalid cell: (#{x}, #{y})") if x < 0 or y < 0 or x >= width or y >= height
      board[y][x]
    
    countNeighborBombs = (x, y) ->
      bombs = 0
      for row in [(y-1)..(y+1)]
        for col in [(x-1)..(x+1)]
          bombs++ if 0 <= row < height and 0 <= col < width and (row isnt y or col isnt x) and board[row][col].bomb
      bombs
    
    @select = (x, y) ->
      cell = getCell x, y
      throw new Error("Can only select unknown cells: (#{x}, #{y})") if cell.mark isnt MinesEngine.UNKNOWN
      
      init?.call @, x, y
      
      if cell.bomb
        # GAME OVER
        @fire 'bomb', x, y, cell.data
        finish.call @, no, x, y, cell.data
        return no
      
      cell.mark = cnt = countNeighborBombs x, y
      @fire 'selected', x, y, cell.data, cnt
      
      if --remainingNonBombs is 0
        # GAME OVER
        finish.call @, yes, x, y, cell.data
      
      cnt
    
    @mark = (x, y, marked) ->
      cell = getCell x, y
      throw new Error("Cannot mark selected cell: (#{x}, #{y})") if cell.mark >= 0
      marked ?= not (cell.mark is MinesEngine.MARKED)
      cell.mark = m = if marked then MinesEngine.MARKED else MinesEngine.UNKNOWN
      
      @fire 'marked', x, y, cell.data, m
      m
    
    @isUnknown = (x, y) -> getCell(x, y).mark is MinesEngine.UNKNOWN
    
    @setData = (x, y, data) -> getCell(x, y).data = data
    @getData = (x, y) -> getCell(x, y).data
    @forAllData = (callback) -> callback getCell(x, y).data for x in [0...width] for y in [0...height]; return
    
    return
  
  
  on: (eventName, listener) -> (@eventListeners[eventName] ?= []).push listener; @
  
  fire: (eventName, data...) -> listener.apply null, data for listener in @eventListeners[eventName] ? []; @
      




if module?.exports?
  module.exports = MinesEngine
else
  (-> @)().MinesEngine = MinesEngine

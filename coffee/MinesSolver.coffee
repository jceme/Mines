EventObject = require?('./EventObject')
EventObject ?= (-> @)().EventObject

MinesEngine = require?('./MinesEngine')
MinesEngine ?= (-> @)().MinesEngine


class MinesSolver extends EventObject
  
  'use strict'
  
  class Cell extends EventObject
    
    constructor: (@engine, @x, @y) -> super()
    
    toString: -> "Cell(#{@x}, #{@y})"
    
    init: (callback) ->
      @getMark()
      @neighbors = []
      for j in [(@y-1)..(@y+1)]
        for i in [(@x-1)..(@x+1)]
          @neighbors.push if i is @x and j is @y then null else callback i, j
      return
    
    evalMark: (@mark) ->
      @remaining = mark if mark >= 0 and not @remaining?
      mark
    
    getMark: -> @mark ? @evalMark @engine.getMark @x, @y
    
    markCell: ->
      return unless @engine.isRunning()
      # TODO
      console.log "Marking #{@}"
      return
    
    onMarked: (marked) ->
      console.log "Event: Marked #{@} #{marked}"
      return
    
    select: ->
      return unless @engine.isRunning()
      @evalMark @engine.select @x, @y
    
    onSelected: (bombCount) ->
      #console.log "Event: Selected #{@}, bomb count is #{bombCount}"
      return
    
    withNeighbors: (callback) ->
      callback cell for cell in @neighbors when cell?
      return
    
    withUnknownNeighbors: (callback) ->
      @withNeighbors (cell) -> callback cell if cell.getMark() is MinesEngine.UNKNOWN
    
    countUnknownNeighbors: ->
      n = 0
      @withUnknownNeighbors -> n++
      n
    
    
    solveTrivial: ->
      result = no
      
      if @remaining? and not @done
        # Release unknown neighbors if no more bombs expected
        if @remaining is 0
          #console.log "Releasing neighbors of #{@}"
          @withUnknownNeighbors (cell) -> cell.select()
          #console.log "Released neighbors of #{@}"
          @done = yes
          result = yes
      
      result
  
  
  
  constructor: (@engine) ->
    super()
    
    # Init local board
    @board = board = ( new Cell(engine, i % w, Math.floor i / w) for i in [0...((w = engine.width) * (h = engine.height))] )
    
    getCell = (x, y) -> board[y * w + x]
    
    # Init cell neighbors
    for cell in board
      cell.init (col, row) -> if 0 <= row < h and 0 <= col < w then getCell(col, row) else null
    
    
    # Forward events to cells
    engine
    .on 'selected', (x, y, _, bombCount) ->
      getCell(x, y).onSelected(bombCount)
    
    .on 'marked', (x, y, _, marked) ->
      getCell(x, y).onMarked(marked)
    
    .on 'bomb', (x, y, _) ->
      console.log "Hit bomb at #{getCell(x, y)}"
    
    .on 'finished', (won, time) ->
      console.log "Game finished after #{time}: won=#{won}"
  
  
  solve: ->
    run = yes
    rounds = 5
    
    while run
      run = no
      if --rounds < 0
        console.log "Rounds over!"
        break
      
      console.log "Trying trivial solve"
      run = cell.solveTrivial() or run for cell in @board
      
      unless run
        # Nothing trivially solved, try one
        # TODO remove
        run = @tryNextCell()
    
    console.log "Finished solving, had #{if rounds < 0 then 'no' else rounds} rounds left"
      
    return
  
  
  tryNextCell: ->
    # TODO use smart try
    result = no
    tryCell = null
    for cell in @board
      if cell.getMark() is MinesEngine.UNKNOWN
        console.log "  Try #{cell}"
        tryCell = cell
        break
    
    if tryCell
      n = tryCell.select()
      console.log "Selected #{cell} -> #{n}"

      if n is no
        console.log "Hit bomb when trying #{cell}"
      else
        result = yes

    else
      console.log "No next try cell found"
    
    result




if module?.exports?
  module.exports = MinesSolver
else
  (-> @)().MinesSolver = MinesSolver

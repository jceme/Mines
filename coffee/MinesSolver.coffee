EventObject = require?('./EventObject')
EventObject ?= (-> @)().EventObject

MinesEngine = require?('./MinesEngine')
MinesEngine ?= (-> @)().MinesEngine


class MinesSolver extends EventObject
  
  'use strict'
  
  class Cell extends EventObject
    
    @BOMB = -100
    
    constructor: (@engine, @x, @y) -> super()
    
    toString: -> "Cell(#{@x}, #{@y})"
    
    formatPrintString: ->
      switch m = @getMark()
        when Cell.BOMB then 'B'
        when MinesEngine.MARKED then 'X'
        when MinesEngine.UNKNOWN then '~'
        when 0 then '_'
        else "#{m}"
    
    init: (callback) ->
      @getMark()
      @neighbors = []
      for j in [(@y-1)..(@y+1)]
        for i in [(@x-1)..(@x+1)]
          @neighbors.push if i is @x and j is @y then null else callback i, j
      return
    
    getMark: -> @mark ?= @engine.getMark @x, @y
    
    markCell: ->
      return unless @engine.isRunning()
      #console.log "Marking #{@}"
      @engine.mark @x, @y, yes
    
    onMarked: ->
      marked = @isMarked()
      
      # Get fresh mark from engine
      delete @mark
      m = @isMarked()
      #console.log "Event: Marked #{@}: #{marked} -> #{m}"
      
      if marked isnt m
        # Decrease (or increase) remaining bombs of neighbors
        @withNeighbors (cell) ->
          if cell.remaining?
            if m then cell.remaining-- else cell.remaining++
            #console.log "Adjusted remaining of #{cell} to #{cell.remaining}"
      return
    
    select: ->
      return unless @engine.isRunning()
      @engine.select @x, @y
    
    onSelected: (bombCount) ->
      @mark = bombCount
      @remaining = bombCount - @countMarkedNeighbors()
      #console.log "Event: Selected #{@}, mark=#{@mark}, remaining=#{@remaining}"
      return
    
    onBomb: ->
      console.log "Hit bomb at #{@}"
      @mark = Cell.BOMB
      return
    
    withNeighbors: (callback) ->
      callback cell for cell in @neighbors when cell?
      return
      
    isUnknown: -> @getMark() is MinesEngine.UNKNOWN
    isMarked: -> @getMark() is MinesEngine.MARKED
    
    withUnknownNeighbors: (callback) ->
      @withNeighbors (cell) -> callback cell if cell.isUnknown()
    
    countUnknownNeighbors: ->
      n = 0
      @withUnknownNeighbors -> n++
      n
    
    withMarkedNeighbors: (callback) ->
      @withNeighbors (cell) -> callback cell if cell.isMarked()
    
    countMarkedNeighbors: ->
      n = 0
      @withMarkedNeighbors -> n++
      n
    
    
    solveTrivial: ->
      result = no
      
      if @remaining?
        
        # Release unknown neighbors if no more bombs expected
        if @remaining is 0
          #console.log "Releasing neighbors of #{@}"
          @withUnknownNeighbors (cell) -> cell.select()
          #console.log "Released neighbors of #{@}"

          delete @remaining
          result = yes
        
        # Mark unknown neighbors if their count matches the count of remaining bombs
        else if @remaining is @countUnknownNeighbors()
          #console.log "Marking neighbors of #{@}"
          @withUnknownNeighbors (cell) -> cell.markCell()
          #console.log "Marked neighbors of #{@}"

          delete @remaining
          result = yes
      
      result
  
  
  
  constructor: (engine) ->
    super()
    
    # Init local board
    @board = board = ( new Cell(engine, i % w, Math.floor i / w) for i in [0...((@boardWidth = w = engine.width) * (h = engine.height))] )
    
    getCell = (x, y) -> board[y * w + x]
    
    # Init cell neighbors
    for cell in board
      cell.init (col, row) -> if 0 <= row < h and 0 <= col < w then getCell(col, row) else null
    
    
    # Forward events to cells
    engine
    .on 'init', (totalBombs) ->
      console.log "Game init: total bombs=#{totalBombs}"
    
    .on 'selected', (x, y, _, bombCount) ->
      getCell(x, y).onSelected(bombCount)
    
    .on 'marked', (x, y, _, marked) ->
      getCell(x, y).onMarked(marked)
    
    .on 'bomb', (x, y, _) ->
      getCell(x, y).onBomb()
    
    .on 'finished', (won, time) =>
      console.log "Game finished after #{time}: won=#{won}"
      @run = no
    
    @run = yes
  
  
  solve: ->
    run = @run
    rounds = 50
    @counterSolve ?= 0
    
    @printBoard 'Starting solve'
      
    while run
      run = no
      if --rounds < 0
        console.log "Solve: Rounds over!"
        break
      
      @counterSolve++
      
      #console.log "Trying trivial solve"
      run = cell.solveTrivial() or run for cell in @board when @run
      
      @printBoard 'After trivial solve'
    
    @printBoard "Finished solving, had #{if rounds < 0 then 'no' else rounds} rounds left"
      
    return
  
  
  autoSolve: ->
    rounds = 10
    @counterAutoSolve ?= 0
    
    while @run
      if --rounds < 0
        console.log "AutoSolve: Rounds over!"
        break
      
      console.log "Next auto-solve round"
      @counterAutoSolve++
      
      break unless @tryNextCell()
      @solve()
    
    console.log "Auto-solve complete: #solve=#{@counterSolve} #autoSolve=#{@counterAutoSolve}"
    @printBoard 'Final board'
    
    return
  
  
  tryNextCell: ->
    # TODO use smart try
    result = no
    tryCell = n = null
    for cell in @board
      if cell.isUnknown()
        if not tryCell or cell.countUnknownNeighbors() > n
          #console.log "  Try #{cell}"
          tryCell = cell
          n = cell.countUnknownNeighbors()
          break if n >= 8
    
    if tryCell
      n = tryCell.select()
      console.log "Selected #{tryCell} -> #{n}"

      if n is no
        console.log "Hit bomb when trying #{tryCell}"
      else
        result = yes

    else
      console.log "No next try cell found"
    
    result
  
  
  printBoard: (msg) ->
    console.log "#{msg}:"
    B = @boardWidth - 1
    s = ''
    @board.forEach (cell) ->
      s += " #{cell.formatPrintString()}"
      if cell.x is B
        console.log s
        s = ''
    return




if module?.exports?
  module.exports = MinesSolver
else
  (-> @)().MinesSolver = MinesSolver

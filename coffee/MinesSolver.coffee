define ['cs!EventObject', 'cs!MinesEngine', 'cs!Region', 'cs!Cell'],
(EventObject, MinesEngine, Region, Cell) -> class MinesSolver extends EventObject
  
  'use strict'
  
  constructor: (engine, @opts = {}) ->
    super()
    
    @opts.roundsSolver ?= Number.MAX_VALUE
    @opts.roundsAutoSolver ?= Number.MAX_VALUE
    @opts.printBoards ?= no
    
    
    # Init local board
    @board = board = ( new Cell(engine, i % w, Math.floor i / w) for i in [0...((@boardWidth = w = engine.width) * (h = engine.height))] )
    
    getCell = (x, y) -> board[y * w + x]
    
    # Init cell neighbors
    for cell in board
      cell.init (col, row) -> if 0 <= row < h and 0 <= col < w then getCell(col, row) else null
    
    
    # Forward events to cells
    engine
    .on 'init', (@totalBombs) =>
      #console.log "Game init: total bombs=#{totalBombs}"
      return
    
    .on 'selected', (x, y, _, bombCount) ->
      getCell(x, y).onSelected(bombCount)
    
    .on 'marked', (x, y, _, marked) ->
      getCell(x, y).onMarked(marked)
    
    .on 'bomb', (x, y, _) ->
      getCell(x, y).onBomb()
    
    .on 'finished', (won, time) =>
      @statsWon = won
      @statsTime = time
      #console.log "Game finished after #{time}: won=#{won}"
      @run = no
    
    @run = yes
  
  
  solve: ->
    run = @run
    rounds = @opts.roundsSolver
    @counterSolve ?= 0
    
    @printBoard 'Starting solve'
    @fire 'solveStarting'
      
    while run
      run = no
      if --rounds < 0
        #console.log "Solve: Rounds over!"
        @fire 'solveRoundBreak', @counterSolve
        break
      
      @counterSolve++
      @fire 'solveNextRound', @counterSolve
      
      #console.log "Trying trivial solve"
      run = cell.solveTrivial() or run for cell in @board when @run
      
      @printBoard 'After trivial solve'
      @fire 'solveTrivialFinished'
    
    @printBoard "Finished solving, had #{if rounds < 0 then 'no' else rounds} rounds left"
    @fire 'solveFinished', @counterSolve
      
    return
  
  
  autoSolve: ->
    rounds = @opts.roundsAutoSolver
    @counterAutoSolve = @counterSolve = 0

    @fire 'autoSolveStarting'
    
    while @run
      if --rounds < 0
        console.log "AutoSolve: Rounds over!"
        @fire 'autoSolveRoundBreak', @counterAutoSolve, @counterSolve
        break
      
      #console.log "Next auto-solve round"
      @counterAutoSolve++
      @fire 'autoSolveNextRound', @counterAutoSolve, @counterSolve
      
      break unless @tryNextCell()
      @solve()
    
    #console.log "Auto-solve complete: #solve=#{@counterSolve} #autoSolve=#{@counterAutoSolve}"
    @printBoard 'Final board'
    @fire 'solveFinished', @counterAutoSolve, @counterSolve
    
    {
      won: @statsWon
      time: @statsTime
      solves: @counterSolve
      autoSolves: @counterAutoSolve
    }
  
  
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
      @fire 'tryNextCell', tryCell
      n = tryCell.select()
      #console.log "Selected #{tryCell} -> #{n}"

      if n is no
        #console.log "Hit bomb when trying #{tryCell}"
        ''
      else
        result = yes

    else
     @fire 'tryNextCellFailed'
     #console.log "No next try cell found"
    
    result
  
  
  printBoard: (msg) ->
    return unless @opts.printBoards
    
    console.log "#{msg}:"
    B = @boardWidth - 1
    s = ''
    @board.forEach (cell) ->
      s += " #{cell.formatPrintString()}"
      if cell.x is B
        console.log s
        s = ''
    return

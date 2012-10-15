define ['Logging', 'cs!EventObject', 'cs!MinesEngine', 'cs!Region', 'cs!Cell'],
(Log, EventObject, MinesEngine, Region, Cell) -> class MinesSolver extends EventObject
  
  'use strict'
  
  log = new Log 'MinesSolver'
  
  
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
      log.info 'Game init: total bombs={}', totalBombs
    
    .on 'selected', (x, y, _, bombCount) ->
      getCell(x, y).onSelected(bombCount)
    
    .on 'marked', (x, y, _, marked) ->
      getCell(x, y).onMarked(marked)
    
    .on 'bomb', (x, y, _) ->
      getCell(x, y).onBomb()
    
    .on 'finished', (won, time) =>
      @statsWon = won
      @statsTime = time
      @run = no
      log.info 'Game finished after {}: won={}', time, won
    
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
        log.debug 'Solve: Rounds over!'
        @fire 'solveRoundBreak', @counterSolve
        break
      
      @counterSolve++
      @fire 'solveNextRound', @counterSolve
      
      log.debug 'Trying trivial solve'
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
      
      log.debug 'Next auto-solve round'
      @counterAutoSolve++
      @fire 'autoSolveNextRound', @counterAutoSolve, @counterSolve
      
      break unless @tryNextCell()
      @solve()
    
    log.info 'Auto-solve complete: #solve={}, #autoSolve={}', @counterSolve, @counterAutoSolve
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
          log.trace '  Try next and better {}', cell
          #console.log ""
          tryCell = cell
          n = cell.countUnknownNeighbors()
          break if n >= 8
    
    if tryCell
      @fire 'tryNextCell', tryCell
      n = tryCell.select()
      log.debug 'Selected {} -> {}', tryCell, n

      if n is no
        log.info 'Hit bomb when trying {}', tryCell
      else
        result = yes

    else
     @fire 'tryNextCellFailed'
     log.warn 'No next try cell found'
    
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

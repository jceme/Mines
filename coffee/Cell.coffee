define ['Logging', 'cs!EventObject'],
(Log, EventObject) -> class Cell extends EventObject
  
  'use strict'
  
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
    #console.log "Hit bomb at #{@}"
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
  
  getUnknownNeighbors: ->
    N = []
    @withUnknownNeighbors (cell) -> N.push cell
    N
  
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

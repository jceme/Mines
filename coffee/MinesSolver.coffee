define ['cs!EventObject', 'cs!MinesEngine'], (EventObject, MinesEngine) -> class MinesSolver extends EventObject
  
  'use strict'
  
  # TODO remove @Region
  @Region = class Region
    
    Max = Math.max
    Min = Math.min
    
    # TODO remove @calc
    @calc: calcSplitMinMax = (oldMin, oldMax, leftSize, rightSize) ->
      if oldMin is oldMax
        leftMax = Min oldMin, leftSize
        rightMax = Min oldMin, rightSize
        
        leftMin = oldMin - rightMax
        rightMin = oldMin - leftMax
      
        [ leftMin, leftMax,   rightMin, rightMax ]
      
      else
        results = ( calcSplitMinMax(n, n, leftSize, rightSize) for n in [oldMin..oldMax] )
        first = results.shift()
        results.reduce(((p, r) -> [ Min(p[0],r[0]), Max(p[1],r[1]),   Min(p[2],r[2]), Max(p[3],r[3]) ]), first)
    
  
    constructor: (members, min, max) ->
      throw new Error("Region: members required") unless members
      throw new Error("Region: Range spec required") unless min?
      @members = []
      @members.push m for m in members when @members.indexOf(m) < 0
      
      # Set amount of bombs expected in this region
      if min? and max?
        throw new Error("Region: max must be >= min: #{max} and #{min}") if max < min
        @min = min; @max = max
      else
        @min = @max = min
      
      if @min < 0 or @max > @members.length
        throw new Error("Region: min..max must be between 0..#{@members.length}: #{@min}..#{@max}")
    
    toString: -> "Region[min=#{@min}, max=#{@max}, members=#{JSON.stringify @members}, special=#{if @isBombFree() then 'FREE' else if @isBombRegion() then 'BOMB' else 'no'}]"
    
    @INTERSECTION_NONE      = 0  # Regions do not intersect
    @INTERSECTION_REAL      = 1  # Regions do really overlap
    @INTERSECTION_CONTAINED = 2  # This region is contained by the argument region
    @INTERSECTION_CONTAINS  = 3  # This region contains the argument region
    @INTERSECTION_EQUAL     = 4  # This region equals the argument region
    
    intersectionType: (region) ->
      len = @members.length
      rmem = region.members
      rlen = rmem.length
      
      if len
        if rlen
          common = (@members.filter (m) -> rmem.indexOf(m) >= 0).length
          switch common
            when 0 then Region.INTERSECTION_NONE
            when len
              if rlen is len then Region.INTERSECTION_EQUAL else Region.INTERSECTION_CONTAINED
            when rlen then Region.INTERSECTION_CONTAINS
            else Region.INTERSECTION_REAL
        
        else Region.INTERSECTION_CONTAINS
      
      else
        if rlen then Region.INTERSECTION_CONTAINED else Region.INTERSECTION_EQUAL
    
    contains: (region) ->
      (type = @intersectionType(region)) is Region.INTERSECTION_CONTAINS or type is Region.INTERSECTION_EQUAL
    
    isBombFree: -> @min is @max is 0
    
    isBombRegion: -> @min is @max is @members.length
    
    cutRegions: (region) ->
      switch type = @intersectionType region
        when Region.INTERSECTION_NONE
          [ @, region ]
        
        when Region.INTERSECTION_REAL
          #console.log "CUT: #{@} intersects #{region}"
          # Split into my part (l), region part (r) and intersection part (i)
          mem = region.members
          lmem = []
          imem = []
          
          for m in @members
            (if mem.indexOf(m) < 0 then lmem else imem).push m
          
          rmem = mem.filter (m) -> imem.indexOf(m) < 0
          #console.log "     mem split: l=#{lmem} and i=#{imem} and r=#{rmem}"
          
          [lmin, lmax,   ilmin, ilmax] = calcSplitMinMax(@min, @max, lmem.length, imem.length)
          [irmin, irmax,   rmin, rmax] = calcSplitMinMax(region.min, region.max, imem.length, rmem.length)
          #console.log "     calc range l: l=#{lmin}-#{lmax} and il=#{ilmin}-#{ilmax}"
          #console.log "     calc range r: ir=#{irmin}-#{irmax} and r=#{rmin}-#{rmax}"
          
          # Merge intersection range
          imin = Max ilmin, irmin
          imax = Min ilmax, irmax
          #console.log "     merged i: #{imin}-#{imax}"
          
          # Adjust outer region parts due to range change
          _lmin = lmin + ilmax - imax
          _lmax = lmax + ilmin - imin
          
          _rmin = rmin + irmax - imax
          _rmax = rmax + irmin - imin
          #console.log "     adjust ranges l: #{lmin}-#{lmax} ==> #{_lmin}-#{_lmax}"
          #console.log "     adjust ranges r: #{rmin}-#{rmax} ==> #{_rmin}-#{_rmax}"
          
          [
            new Region(lmem, _lmin, _lmax)
            new Region(imem, imin, imax)
            new Region(rmem, _rmin, _rmax)
          ]
        
        when Region.INTERSECTION_CONTAINED
          region.cutRegions @
        
        when Region.INTERSECTION_CONTAINS
          #console.log "CUT: #{@} contains #{region}"
          # Split my region into my region (only) part and region part
          regmem = region.members
          mymem = @members.filter (m) -> regmem.indexOf(m) < 0
          #console.log "     mem split: my=#{mymem} and region=#{regmem}"
          
          [mymin, mymax,   regmin, regmax] = calcSplitMinMax(@min, @max, mymem.length, regmem.length)
          #console.log "     calc range: my=#{mymin}-#{mymax} and region=#{regmin}-#{regmax}"
          
          # Narrow calculated region range by region's original range
          _regmin = Max regmin, region.min
          _regmax = Min regmax, region.max
          #console.log "     narrow region range: #{regmin}-#{regmax} ==> #{_regmin}-#{_regmax}"
          
          # Adjust my region part due to range change
          _mymin = mymin + regmax - _regmax
          _mymax = mymax + regmin - _regmin
          #console.log "     adjust my range: #{mymin}-#{mymax} ==> #{_mymin}-#{_mymax}"
          
          [
            new Region(mymem, _mymin, _mymax)
            new Region(regmem, _regmin, _regmax)
          ]
        
        when Region.INTERSECTION_EQUAL
          [ new Region(@members, Max(@min, region.min), Min(@max, region.max)) ]
        
        else throw new Error("Unsupported intersection type: #{type}")
  
  
  
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

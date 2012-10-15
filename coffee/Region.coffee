define ['Logging'],
(Log) -> class Region
  
  'use strict'
  
  log = new Log 'Region'
  
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
        log.debug 'CUT: {} intersects {}', @, region
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
        log.debug 'CUT: {} contains {}', @, region
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

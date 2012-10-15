require ['cs!MinesEngine'], (MinesEngine) ->

  table = $ '<table class="mines mines-table">'
  table.appendTo '#board'
  
  rows = cols = 10
  ratio = 0.1
  
  engine = new MinesEngine rows, cols, ratio
  
  disableAll = ->
    engine.forAllData (c) -> c.button
      disabled: yes
  
  engine
  .on 'init', (totalBombs) ->
    console.log "Inited with #{totalBombs} total bombs"
  
  .on 'timer', (secs) ->
    #console.log "Timer: #{secs}"
    return
  
  .on 'finished', (won, time, x, y, cell) ->
    console.log "Finished game #{if won then 'WITH' else 'without'} winning after #{time} seconds"
    disableAll()
  
  .on 'bomb', (x, y, cell) ->
    cell.button
      disabled: yes
      label: 'B'
  
  .on 'selected', (x, y, cell, neighbors) ->
    cell.button
      disabled: yes
      label: "#{neighbors}"
            
    if neighbors is 0
      for row in [(y-1)..(y+1)]
        for col in [(x-1)..(x+1)]
          if 0 <= row < rows and 0 <= col < cols and (row isnt y or col isnt x) and engine.isUnknown col, row
            engine.getData(col, row).click()
    return
  
  .on 'marked', (x, y, cell, marked) ->
    console.log "Marked cell (#{x}, #{y}) #{marked}"
  
  
  
  for y in [0...rows]
    row = $ '<tr>'
    row.appendTo table
    for x in [0...cols] then do (x, y) ->
      row.append cell = $ "<td><label for='mine_#{x}_#{y}'></label><input id='mine_#{x}_#{y}' type='checkbox'/></td>"
      
      cell = cell.find('input')
      
      engine.setData x, y, cell
      
      cell.button
        label: ' '
      .on 'click', ->
        try
          engine.select x, y
        catch e
          console.log e
        return

require ['cs!MinesEngine', 'cs!MinesSolver'], (MinesEngine, MinesSolver) ->

  engine = new MinesEngine 80, 20, 0.101,
    noTimer: on
  
  solver = new MinesSolver(engine)
  result = solver.autoSolve()
  
  console.log "Finished auto-solving: #{JSON.stringify result}"
  engine.destroy()
  
  console.log "YOU #{if result.won then 'WON' else 'LOST'} THE GAME AFTER #{result.time} seconds."

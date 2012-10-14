MinesEngine = require('./MinesEngine')
MinesSolver = require('./MinesSolver')


testRun = (opts = {}) ->
  engineOpts = opts.engineOpts ? {}
  engineOpts.noTimer = on
  
  engine = new MinesEngine opts.width or 80, opts.height or 20, opts.ratio or 0.1, engineOpts
  
  solver = new MinesSolver engine, opts.solverOpts
  
  
  result = solver.autoSolve()
  
  #console.log "Finished auto-solving: #{JSON.stringify result}"
  engine.destroy()
  #console.log "YOU #{if result.won then 'WON' else 'LOST'} THE GAME AFTER #{result.time} seconds."
  #console.log result
  result


multiRun = (opts = {}) ->
  runs = opts.runs || 10
  stats = ( testRun(opts) for [0...runs] )
  
  avg = (field) -> Math.round(stats.reduce(((prev, s) -> prev + s[field]), 0) / runs * 1000) / 1000
  
  {
    won: stats.filter((s) -> s.won).length
    lost: stats.filter((s) -> not s.won).length
    avgTime: avg 'time'
    avgSolves: avg 'solves'
    avgAutoSolves: avg 'autoSolves'
  }



console.log multiRun
  runs: 100
  width: 80
  height: 20
  ratio: 0.101

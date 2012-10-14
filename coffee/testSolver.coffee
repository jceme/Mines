MinesEngine = require('./MinesEngine')
MinesSolver = require('./MinesSolver')


won = time = null

engine = new MinesEngine(80, 20, 0.101)
engine.on 'finished', (_won, _time) -> won = _won; time = _time

solver = new MinesSolver(engine)
solver.autoSolve()

console.log "Finished auto-solving"
engine.destroy()

console.log "YOU #{if won then 'WON' else 'LOST'} THE GAME AFTER #{time} seconds."

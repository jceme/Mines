MinesEngine = require('./MinesEngine')
MinesSolver = require('./MinesSolver')


engine = new MinesEngine(5, 5, 0.1)

solver = new MinesSolver(engine)
solver.autoSolve()

console.log "Finished auto-solving"
engine.destroy()

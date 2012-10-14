MinesEngine = require('./MinesEngine')
MinesSolver = require('./MinesSolver')


engine = new MinesEngine(5, 5, 0.1)

solver = new MinesSolver(engine)
solver.solve()

console.log "Finished solving"
engine.destroy()

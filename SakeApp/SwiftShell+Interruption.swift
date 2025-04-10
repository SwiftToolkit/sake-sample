import Sake
import SwiftShell

func interruptableRunAndPrint(bash command: String, interruptionHandler: Command.Context.InterruptionHandler) throws {
    let asyncCommand = runAsyncAndPrint(bash: command)
    interruptionHandler.register(asyncCommand)
    try asyncCommand.finish()
}

func interruptableRunAndPrint(_ executable: String, _ args: Any ..., interruptionHandler: Command.Context.InterruptionHandler) throws {
    let asyncCommand = runAsyncAndPrint(executable, args)
    interruptionHandler.register(asyncCommand)
    try asyncCommand.finish()
}

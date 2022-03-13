import os
import osproc
import strutils

const supportedHooks = [
    "applypatch-msg",
    "pre-applypatch",
    "post-applypatch",
    "pre-commit",
    "pre-merge-commit",
    "prepare-commit-msg",
    "commit-msg",
    "post-commit",
    "pre-rebase",
    "post-checkout",
    "post-merge",
    "pre-push",
    "pre-receive",
    "update",
    "proc-receive",
    "post-receive",
    "post-update",
    "reference-transaction",
    "push-to-checkout",
    "pre-auto-gc",
    "post-rewrite",
    "sendemail-validate",
    "fsmonitor-watchman",
    "p4-changelist",
    "p4-prepare-changelist",
    "p4-post-changelist",
    "p4-pre-submit",
    "post-index-change",
]
const repoHookDirs = [
    joinPath(".git", "hooks"),
    ".githooks",
]

let self = absolutePath(paramStr(0))
let hookerDir = joinPath(getHomeDir(), ".git-hooker")
let delegateDir = joinPath(hookerDir, "delegates")
let globalHooksDir = joinPath(hookerDir, "hooks")

proc printHelpAndExit() =
    echo "git-hooker <cmd> <args>"
    echo ""
    echo "commands:"
    echo "  install"
    echo "  run <hook> <args>"
    quit(QuitFailure)

proc install() =
    createDir(delegateDir)
    createDir(globalHooksDir)

    for hook in supportedHooks:
        let hookFile = joinPath(delegateDir, hook)
        let f = open(hookFile, fmWrite)
        f.writeLine("#!/bin/sh")
        f.writeLine(self, " run ", hook, " $*")
        close(f)
        setFilePermissions(hookFile, {fpUserRead, fpUserWrite, fpUserExec, fpGroupRead, fpGroupExec, fpOthersRead, fpOthersExec})

    let p = startProcess("git", args=["config", "--global", "core.hookspath", delegateDir], options={poUsePath, poParentStreams})
    let rc = p.waitForExit()
    close(p)

    if rc != 0:
        echo "Error setting hooks path."
        quit(QuitFailure)
    
    echo "Updated git with new hooks path."

proc run() =
    var hookPaths = newSeq[string]()
    for hookDir in walkDir(globalHooksDir):
        if (hookDir.kind == pcLinkToDir) or (hookDir.kind == pcDir):
            hookPaths.add(hookDir.path)
    
    let cwd = getCurrentDir()
    for hookDir in repoHookDirs:
        hookPaths.add(joinPath(cwd, hookDir))

    let hookName = paramStr(2)
    var hookArgs = newSeq[string](paramCount() - 2)
    for i in 3 .. paramCount():
        hookArgs.add(paramStr(i))

    for hookPath in hookPaths:
        let hookFile = joinPath(hookPath, hookName)
        if not fileExists(hookFile):
            continue

        echo("Executing hook ", hookFile)
        let p = startProcess(hookFile, args=hookArgs, options={poParentStreams})
        let rc = p.waitForExit()
        close(p)

        if rc != 0:
            echo "Hook failed."
            quit(rc)

if paramCount() < 1:
    printHelpAndExit()

case toLower(paramStr(1)):
    of "install":
        install()
    of "run":
        if paramCount() < 2:
            printHelpAndExit()
        run()
    else:
        printHelpAndExit()

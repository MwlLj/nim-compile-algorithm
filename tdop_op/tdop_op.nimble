# Package

version       = "0.1.0"
author        = "MwlLj"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["tdop_op"]



# Dependencies

requires "nim >= 1.0.2"

import strformat
task run, "Run":
    let t = "target"
    var target = "target"
    var name = bin[0]
    mkdir target
    echo("build start")
    exec "nimble build"
    echo("build finish")
    when defined(windows):
        name.add(".exe")
    target.add("/")
    target.add(name)
    try:
        cpFile(name, target)
        rmFile(name)
        cd t
        when defined(linux):
            exec(fmt"chmod +x {name}")
        echo("***start exec***")
        when defined(linux):
            exec(fmt"./{name}")
        else:
            exec(fmt"{name}")
        echo("***exec end***")
    except:
        echo("unknow except")

task clear, "Clear":
    rmDir("target")

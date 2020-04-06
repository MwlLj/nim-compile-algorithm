# Package

version       = "0.1.0"
author        = "MwlLj"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["lexical_analysis"]



# Dependencies

requires "nim >= 1.0.2"

requires "https://github.com/MwlLj/nim-parse >= 0.1.0"

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
        when defined(linux):
            exec(fmt"chmod +x {name}")
        cd t
        echo("***start exec***")
        exec(fmt"{name}")
        echo("***exec end***")
    except:
        echo("unknow except")

task clear, "Clear":
    rmDir("target")

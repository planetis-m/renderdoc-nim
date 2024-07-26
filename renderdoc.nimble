# Package

version     = "0.1.0"
author      = "Antonis Geralis"
description = "renderdoc bindings"
license     = "MIT"
srcDir      = "src"

# Deps

requires "nim >= 2.0.0"

import std/distros

foreignDep "renderdoc"

after install:
  echo "To complete the installation, run:\n"
  echoForeignDeps()

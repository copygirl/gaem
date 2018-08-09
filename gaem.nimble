import src/config

# Package

version     = VERSION
author      = "copygirl"
description = "A never finished dream game based on ECS design"
license     = "MIT"

srcDir  = "src"
bin     = @["gaem"]

skipExt = @["nim"]

# Dependencies

requires "nim >= 0.18.0"
requires "sdl2 >= 1.2"
requires "opengl >= 1.1.0"
requires "glm >= 1.1.1"

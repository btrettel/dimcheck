#!/usr/bin/env -S python3 -Werror
# -*- coding: utf-8 -*-

import os
from subprocess import run, PIPE

with open(os.path.join("src", "revision.f90"), "w") as output_handler:
    output_handler.write("character(len=*), public, parameter :: REVISION = \"")
    result = run(["git", "rev-parse", "--short", "HEAD"], stdout=PIPE, stderr=PIPE, universal_newlines=True)
    output_handler.write(result.stdout.strip())
    output_handler.write("\"\n")
    
    output_handler.write("character(len=*), public, parameter :: REVISION_DATE = \"")
    result = run(["git", "show", "--no-patch", "--format=%ci", "HEAD"], stdout=PIPE, stderr=PIPE, universal_newlines=True)
    output_handler.write(result.stdout.strip())
    output_handler.write("\"\n")
    
    output_handler.write("logical, public, parameter :: MODIFIED = ")
    result = run(["git", "diff", "--exit-code", "--quiet"], stdout=PIPE, stderr=PIPE, universal_newlines=True)
    if result.returncode == 0:
        output_handler.write(".false.\n")
    else:
        output_handler.write(".true.\n")

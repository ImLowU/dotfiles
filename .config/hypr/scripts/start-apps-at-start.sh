#!/bin/bash

hyprctl dispatch 'hl.dsp.exec_cmd("kitty -e rmpc", {workspace="4 silent"})'
hyprctl dispatch 'hl.dsp.exec_cmd("codium", {workspace="2 silent"})'
hyprctl dispatch 'hl.dsp.exec_cmd("vesktop -m", {workspace="8 silent"})'

#!/bin/bash

sed -i -e "s/eDP-1, preferred,auto,1.333333, vrr, 1/eDP-1, disable/g" ~/.config/hypr/components/monitors.conf
hyprctl reload


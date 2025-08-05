#!/bin/bash

sed -i -e "s/eDP-1, disable/eDP-1, preferred,auto,1.333333, vrr, 1/g" ~/.config/hypr/components/monitors.conf
hyprctl reload


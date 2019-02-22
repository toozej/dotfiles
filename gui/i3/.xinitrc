xrandr -s 1920x1200
export TERM="rxvt-unicode"
autocutsel -fork &
autocutsel -selection PRIMARY -fork &
xset r rate 250 20
exec i3
vmware-user-suid-wrapper

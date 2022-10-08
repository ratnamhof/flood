
# goal

Flood fill puzzle game implemented in bash.

The flooded field consist of all identically colored tiles connected to the one in the top-left corner. This area is extended by changing the color of the flooded patch, absorbing all neighbouring tiles with the new color. The game is won by flooding the entire board within the indicated maximum number of turns.

# command line options

```
flood [-ht] [-b boardsize] [-c nrcolors] [-l layout] [-s seed]

  -h,--help    display this help text
  -t,--tight   use tight board layout

  -b,--board   integer in set 4:2:26 representing the board size
  -c,--colors  integer in set 3:8 representing the nr of colors
  -l,--layout  string in the set {colors, letters, numbers} representing
               the board layout
  -s,--seed    integer seed for the pseudo-random number generator
```

# in-game key mappings

## game board

 | Key               | Action                     |
 |:-----------------:|:--------------------------:|
 | r,1               | change color to red        |
 | g,2               | change color to green      |
 | y,3               | change color to yellow     |
 | b,4               | change color to dark blue  |
 | m,5               | change color to magenta    |
 | c,6               | change color to cyan       |
 | d,7               | change color to dark gray  |
 | w,8               | change color to light blue |
 | h,left            | move selection left        |
 | l,right           | move selection right       |
 | j,enter,space,tab | apply selection            |
 | u                 | undo previous change       |
 | e                 | enter seed                 |
 | a                 | replay game                |
 | n                 | new game                   |
 | q                 | quit game                  |
 | z                 | continue beyond GAME OVER  |
 | s                 | change settings            |
 | i                 | display goal               |
 | x                 | redraw screen              |
 | ?                 | display key bindings       |

## settings menu

| Key               | Action                         |
|:-----------------:|:------------------------------:|
| h,left            | move selection left            |
| l,right           | move selection right           |
| j,down            | move to next settings item     |
| k,up              | move to previous settings item |
| a,enter,space,tab | apply changes                  |
| x                 | discard changes                |
| ?                 | display key bindings           |
| q                 | quit game                      |


embroidery
==========

MATLAB m-files for viewing and writing .exp embroidery machine files
With this you can generate a plot within MATLAB, then output it to be stitched.
Tested on a borrowed Bernina embroidery machine. The first stitch is at position 0,0. 
The first stitch tends to unravel--further work is needed here
(Or just stitch back and forth with the machine before starting the embroidery pattern)

The first commit contains two m-files, expview.m and expwrite.m
expview.m reads an .exp formatted embroidery file and plots it within MATLAB
expwrite.m takes a list of x-y points and turns it into an .exp file

The initial files don't do "color changes" or "jumps."
Color changes mean the machine stops and signals you to change thread.
Jumps prevent the machine from doing a stitch at a given x-y coordinate,
instead you skip along to the next x-y coordinate---
making a long hanging thread that you can easily trim later.

This means the stitched pattern will have an "Etch a Sketch" appearance:
one long continuous line of a single color.


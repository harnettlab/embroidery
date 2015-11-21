embroidery
==========

MATLAB m-files for viewing and writing .exp embroidery machine files. 
Nov 2015 update: viewing .pes files is now possible using pesdecode2.m

And expalignjump.m will rotate and translate your x-y data to a pair of alignment marks, then write an .exp file.
It will also make a centered 9x9cmbox in a 2nd color so the machine won't force your aligned data to the center.
These .exp files were translated to .pes format using the StitchBuddy iPad app and worked on a Brother machine.
Test data for expalignjump is available in stitchXY.mat, which contains stitchxdata and stitchydata.
 expalignjump(stitchxdata,stitchydata,[-30 0 30 0]) will create a file aligned with marks at (-30,0) and (30,0) mm.

With expwrite.m you can generate a plot within MATLAB, then output it to be stitched.
The exp files it produced ran on a borrowed Bernina embroidery machine. The first stitch is at position 0,0. 
The first stitch tends to unravel--further work is needed here
(Or just stitch back and forth with the machine before starting the embroidery pattern)

The first commit contains two m-files, expview.m and expwrite.m.

expview.m reads an .exp formatted embroidery file and plots it within MATLAB.

expwrite.m takes a list of x-y points and turns it into an .exp file.

The initial files don't do "color changes" or "jumps."
Color changes mean the machine stops and signals you to change thread.
Jumps prevent the machine from doing a stitch at a given x-y coordinate,
instead you skip along to the next x-y coordinate---
making a long hanging thread that you can easily trim later.

This means the stitched pattern will have an "Etch a Sketch" appearance:
one long continuous line of a single color.


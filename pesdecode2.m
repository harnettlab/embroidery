%Trying to decode PES embroidery format from my own data after converting
%Load a file and extract the coordinates
%For alignment, I would like to measure 2 alignment marks,
%then be able to do precise rotations/translations and export a
%usable PES that will be in the right location.
%CKH Oct 3 2015
fid=fopen('lissajous1-1.pes','r');%This pes file was an EXP
%that I made using my old expwrite script, and then 
%converted to PES using StitchBuddy and successfully sewed on
%the Brother PE525. (I had to scale the size way down before
%StitchBuddy would convert it)


B=fread(fid);% B is 7113x1  double. The file has 1000 stitches and one color
%Who knows what size I want it to be.

%Inspecting file there is a starter in ASCII
%    #PES0001 
% Bytes 8, 9 & 10 (or in Matlab, B(9,10,11) bc it starts at 1, not 0)
% Previous file had byte 128, then byte 13, then 0
% This one has 24 16 0,  24 +16*256  would be byte 4120 (4121 if we start at 1)
% It seems to point to the very first location AFTER the stitch data
%  then probably some size data. 
%
pecstart=B(9)+256*B(10)+65536*B(11);

%The first huge chunk of coordinate data repeats in a pattern of 4. This is the stitch coord data
%I think this absolute-position data is used for plotting and editing,
%and then we use it to generate the relative data (PEC data) 
%and also the black/white image for the LCD. 

% X LSB, X MSB, Y LSB, Y MSB
y=B(111:(110+(4*1001)));  %both my files seem to start 
%the 2 byte stitch pattern around 100-130 but not exactly ughhh
%Besides B(9,10,11), the first difference between the two files is at
%B(32)thru B(46). It's 250 1 53 3 214 for the swirly file, and 214 2 214 2 250

%I see the number of stitches at B(109:110). 1000=232+3*256 In the other file, 
%the number of stitches is at A(125:126). 826=58+3*256 %Maybe look for 124
y=reshape(y,4,1001)';

%Have to convert X MSB to two's complement and Y MSB, same
%Is there a built in function that does it? int8 does not do it
msxbyte=y(:,2);
msxbyte(msxbyte>127)=msxbyte(msxbyte>127)-256;
%msxbyte(msxbyte==254)=-2;
%msxbyte(msxbyte==255)=-1;
%msxbyte(msxbyte==128)=0;

msybyte=y(:,4);
msybyte(msybyte>127)=msybyte(msybyte>127)-256;
%msybyte(msybyte==254)=-2;
%msybyte(msybyte==255)=-1; 
%msybyte(msybyte==128)=0;   %this covered all the cases in this file

xcoord=msxbyte*256+y(:,1);
ycoord=msybyte*256+y(:,3);

ycoord=-ycoord; %I had it upside down from the photo
plot(xcoord,ycoord,'b*-');
axis equal;

%I don't know where the x-y scaling information goes.
%what is all the junk at the end? beyond the end of this coord data 
% 
% %Mystery information: number of colors, graphic location, size.
maybecolors=B(pecstart+49);%both my single color files say 0 here
graphicloc=B(pecstart+515)+B(pecstart+516)*256+B(pecstart+517)*65536;
xsize=B(pecstart+521)+256*B(pecstart+522); %gives 547 for this design
ysize=B(pecstart+523)+256*B(pecstart+524);  %is that 5.47 cm?

% 
% %There is a block that I thought would be an image
% %Instead it seems like offsets to drive the motors based
% %on the previous stitch location. 
% %This is a chunk of numbers btw 0 and
% %128 with a gap in the histogram, no numbers around 80ish
% %that makes them seem like signed 7 bit numbers.
%THIS NEEDS SOME TWEAKING TO FIND JUMP STITCHES AND COLOR CHANGES
%but it works only because we don't have those in the test file.
%I am guessing there are 3 start/color bytes, 255, 144,1 and we need to
%jump over them to actually plot the data
maybeimg=B((pecstart+1+533+3):(pecstart+1+graphicloc+512-2));%offset by 1 bc Matlab starts at 1
%And I chopped off three start bits (255-144-1) and two end bits (255-0)
%making maybeimg length 2000 (one x, one y coord) when I had 1000 stitches.
%Same code worked on a different single-color file that had 826 stitches.
maybeimg(maybeimg>63)=maybeimg(maybeimg>63)-128;%okay there are some special
%jump, color change and end things at high values too.
x2=cumsum(downsample(maybeimg,2));%accumulate x motion
y2=-cumsum(downsample(maybeimg(2:end),2));%get every other pair, accumulate y motion
figure()
plot(x2,-y2);%should look similar to data plot
axis equal;
% 
% 
% 
% %At the end of the file is a 1-bit graphic of the pattern to
% %display on an embroidery machine's LCD.
graphic=B((pecstart+graphicloc+513):end); %same code worked on 2 different test files
m2bits=double(dec2bin(graphic))-48;%converts each value to 8 bits
m2bits=m2bits';
m2bits=flipud(m2bits);%fix it up so reshape works properly
tryit=reshape(m2bits(1:(48*76)),48,76);%jiggle the row length until a picture assembles
figure()
image(tryit'*255)
colormap(flipud(gray))
axis equal
axis tight
% %It was 2 copies of a 39x48 1-bit image of the pattern, stacked on top of each other
% %for a 76x48 image overall. There's a border around the edge of each.
% %That's the end of the file.
% 
% 
% %This person also dissected .pes http://www.achatina.de/sewing/main/TECHNICL.HTM
% %suggesting the final data is a pixel graphic of the file. I pasted the data below.
%  OK it makes sense if we call the relative data the "PEC data."
%  Why there were 2 copies of my image here?

% HEX 0008 - 0010	pecstart	3 Bytes, pointing to beginning of PEC codeblock stored in PES file, LSB first
% pecstart + 49		No. of colors in file
% pecstart + 515	graphic	3 Bytes pointing to beginning of pixel graphic, LSB first
% pecstart + 521		2 Bytes, x-size of design, LSB first
% pecstart + 523		2 Bytes, y-size of design, LSB first
% pecstart + 533		Beginning of stitch data
% pecstart + graphic + 512		End of stitch data
% pecstart + graphic + 513		228 Byte pixel graphic, each bit = one pixel, drawn from top left to bottom right
% Examples :
% 
% Byte values:	No. of Bytes:	Explanation
% kx=254, ky=176, 
% NN	3	Color change, Byte following ky gives color No. Stitch data (2-4 Bytes) follows
% 128 <= kx <= 254,
% ky	2	Jump stitch, lower four bytes (nibble) of kx is multiplication factor for jump stitch ky, direction of jump is determined as follows:
% (kx and 15) <= 7		jump in positive direction. length = ky + (kx and 15) x 256
% (kx and 15) >=8		jump in negative direction. length = (ky-256) + ((kx and 15)-15) x 256
% kx,ky	2	Regular stitch data
% 0 <= kx <= 63 : positive
% 64 <= kx <= 127 : negative, kx=kx-128
% 0 <= ky <= 63 : positive
% 64 <= ky<= 127 : negative, ky=ky-128
% 
% kx = 255,
% ky = 0
function [vx,dx,dy] = expwrite(x,y)
%Give it an ordered list of x,y points to write (any dimension) 
%Generates a string you could save as a .exp file and open on an
%embroidery machine
%Does not do color changes or jumps (Etch-a-Sketch style)
%CKH 12-21-13

%Round it off before taking dx and dy to avoid accumulated error
dx=diff(x);
dy=diff(y);

%Find the extent of the matrix
dxmax=max(max(abs(dx)));
dymax=max(max(abs(dy)));%maximum allowed is 127
%minimum allowed is 0
diffmax=max([dxmax,dymax]);


%Scale the ORIGINAL matrices, then round them off
x=round(x*127/diffmax);
y=round(y*127/diffmax);

%plot(x,y)%check it out

%Recalc the differences dx and dy after scaling & roundoff
dx=diff(x);
dy=diff(y);

%Shift the negative values to positive
dx(dx<0)=dx(dx<0)+256;
dy(dy<0)=dy(dy<0)+256;

%Cast the values into uint8 format, this will round things off
dx=uint8(dx);
dy=uint8(dy);

%Shift any dx or dy who is 128, down to 127 or the machine will think this is a
%jump or color change
skipx=find(dx==128);
skipy=find(dy==128);
dx(skipx)=127;
dy(skipy)=127;

%Make up the gap by adding 1 to the next value 
%to prevent accumulated errors
%dx(skipx+1)=dx(skipx+1)+1;
%dy(skipy+1)=dy(skipy+1)+1;
%(but what if that was 127?) live with errors for now

%Compact things into a single interleaved vector format
vx=[dx;dy];
vx=[0;0;vx(:)];%0,0 marks start of all my files

%Save this, should then be able to open with expview
fid=fopen('lissajous1.EXP','w');%create new file for writing
fwrite(fid,vx);



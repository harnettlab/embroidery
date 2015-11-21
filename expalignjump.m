function [vx,dx,dy] = expalignjump(x,y,measmarks,drawnmarks)
%CKH Nov 2015 Give expAlign2 a list of x,y points in mm to write 
%And measmarks, the measured position of two aligment marks on
%the machine. Use the machine's needle and stage to move
%to both alignment marks, write down the coords in mm
%and enter into "measmarks" [xleft,yleft,xright,yright].
%Rotates and moves the origin of the design to match the marks
%Then tries to insert a jump stitch when delta-x or delta-y is greater than
%12.7mm
%Then draws a 9x9cm centered bounding box in a 2nd color 
%so that the aligned design stays centered.
%Generates and saves your x-y points as a .exp file to take back to the 
%embroidery machine, and embroider an aligned design. 

%Purpose: put marks at +/- 3 cm on a laser-cut or 3D printed or
%rubber-stamped pattern, put that in a hoop, measure the
%marks' location and this function can align stitches with it

measxleft=measmarks(1);
measyleft=measmarks(2);
measxright=measmarks(3);
measyright=measmarks(4);
if(nargin<4)%Location of true alignment marks is standard default.
    %left mark at (x,y)=(-30 mm,0) and right at (+30 mm, 0)
    drawnmarks=[-30 0 30 0]
end%I will assume these marks are ALWAYS supposed to be on a horizontal line
%but they are allowed to have nonstandard spacing and y position.
drawnxleft=drawnmarks(1);
drawnyleft=drawnmarks(2);
drawnxright=drawnmarks(3);
drawnyright=drawnmarks(4);
drawnxcenter=mean([drawnxleft,drawnxright]);
drawnycenter=mean([drawnyleft,drawnyright]);%ought to be same y value

measxcenter=mean([measxleft, measxright]);
measycenter=mean([measyleft, measyright]);
tanangle=(measyright-measyleft)/(measxright-measxleft);
offangle=atan(tanangle);

shift=[measxcenter-drawnxcenter,measycenter-drawnycenter]
[theta,r]=cart2pol(x,y);
[x,y]=pol2cart(theta+offangle,r)
x=x+shift(1);
y=y+shift(2);

dx=diff(x);
dy=diff(y);

%Find the extent of the matrix
dxmax=max(max(abs(dx)));
dymax=max(max(abs(dy)));%maximum allowed is 127
%minimum allowed is 0
diffmax=max([dxmax,dymax]);


%Scale the data from mm to 10xmm, then round it off
x=round(x*10);
y=round(y*10);
xjumploc=find(abs(diff(x))>127);
xjumploc=xjumploc+(0:(length(xjumploc)-1))';%locations to add jumps
for i=1:length(xjumploc)%mark jumps with a j
    jump=sign(x(xjumploc(i)+1)-x(xjumploc(i)))*127;
    x=[x(1:xjumploc(i));x(xjumploc(i))+jump+j;x((xjumploc(i)+1):end)];
    y=[y(1:xjumploc(i));y(xjumploc(i));y((xjumploc(i)+1):end)];
end

yjumploc=find(abs(diff(y))>127);
yjumploc=yjumploc+(0:(length(yjumploc)-1))';
for i=1:length(yjumploc)
    jump=sign(y(yjumploc(i)+1)-y(yjumploc(i)))*127;
    x=[x(1:yjumploc(i));x(yjumploc(i));x((yjumploc(i)+1):end)];
    y=[y(1:yjumploc(i));y(yjumploc(i))+jump+j;y((yjumploc(i)+1):end)];
end

xjumplocs=find(imag(x)>0);%get the modified x locations 
yjumplocs=find(imag(y)>0);%and y-jump locations
x=real(x)';%back to normal
y=real(y)';%back to normal

%This will take care of anything <25.4 mm
if max(abs([diff(x),diff(y)]))>127
    disp('ERROR: Your aligned file has a jump that is > 25.4 mm')
    return
end

plot(x,y)%check it out
hold on
plot(x(xjumplocs),y(xjumplocs),'ro')
plot(x(yjumplocs),y(yjumplocs),'rx')
axis equal
%Calc the differences dx and dy after scaling & roundoff
dx=diff(x)
dy=diff(y)

%Shift any negative values to positive
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

%Iterate through original dx and dy and insert jumps
origdx=dx;
origdy=dy;
dx=[];
dy=[];
for i=1:length(origdx)
    if ((ismember(i+1,[xjumplocs;yjumplocs]))|(ismember(i,[xjumplocs;yjumplocs])))%i or i+1 is in xjumplocs or yjumplocs insert a jump to each array
       dx=[dx 128];
       dy=[dy 2];
    end 
    dx=[dx origdx(i)];%then append the next value
    dy=[dy origdy(i)];%and go thru the entire array
end
    

%Compact things into a single interleaved vector format
vx=[dx(:)';dy(:)'];
vx=vx(:);
[JumpToStart,JumpToOrigin]=autojump(x,y);
vx=[JumpToStart(:);vx;JumpToOrigin(:)];
colorchange=[128,1,0,0];
border=getborder();
vx=[vx;colorchange(:);border(:)];%Add color change & then border
fid=fopen('jumpreal.exp','w');%create new file for writing
fwrite(fid,vx);
end

function [jumpstart jumpend]=autojump(x,y)
%jump to start from 0,0 and jump back to 0,0 from end
xstart=x(1); ystart=y(1);
NBigXStart=fix(xstart/125);%how many 12.5 mm jumps to do
LittleXStart=xstart-125*NBigXStart;%the rest of the stitch
NBigYStart=fix(ystart/125);
LittleYStart=ystart-125*NBigYStart;

if(xstart>0) %create jumps of the right sign
    xBigStartJump=125;
    tidgitXstart=LittleXStart;%the last little bit
else
    xBigStartJump=131;%-125
    tidgitXstart=256+LittleXStart;%the last little bit is <0
end;

if (ystart>0)
    yBigStartJump=125;
    tidgitYstart=LittleYStart;
else
    yBigStartJump=131;%-125
    tidgitYstart=256+LittleYStart;
end;

jumpstart=[];%Doing all x, and then all y jumps
%in case there are a different nmber
for j=1:abs(NBigXStart)
    jumpstart=[jumpstart 128 2 xBigStartJump 0];%big X jumps
end
jumpstart=[jumpstart 128 2 tidgitXstart 0];%that last x bit

for j=1:abs(NBigYStart)
    jumpstart=[jumpstart 128 2 0 yBigStartJump];%big Y jumps
end;
jumpstart=[jumpstart 128 2 0 tidgitYstart];%last y bit

%Now repeat the process after the end of stitches
%to return to origin (then later draw bounding box)
xend=x(end);
yend=y(end);
NBigXEnd=fix(-xend/125);%minus sign from trying to get back to origin
LittleXEnd=-xend-125*NBigXEnd;
NBigYEnd=fix(-yend/125);
LittleYEnd=-yend-125*NBigYEnd;

if(-xend>0) %create jumps of the right sign
    xBigEndJump=125;
    tidgitXend=LittleXEnd;%the last little bit
else
    xBigEndJump=131;%-125
    tidgitXend=256+LittleXEnd;%the last little bit is <0
end;

if (-yend>0)
    yBigEndJump=125;
    tidgitYend=LittleYEnd;
else
    yBigEndJump=131;%-125
    tidgitYend=256+LittleYEnd;
end;

jumpend=[];%this is working back to origin
%in case there are a different nmber
for j=1:abs(NBigXEnd)
    jumpend=[jumpend 128 2 xBigEndJump 0];%big X jumps
end
jumpend=[jumpend 128 2 tidgitXend 0];%that last x bit

for j=1:abs(NBigYEnd)
    jumpend=[jumpend 128 2 0 yBigEndJump];%big Y jumps
end;
jumpend=[jumpend 128 2 0 tidgitYend];%last y bit
end%end of autojump subfunction

function borderbox=getborder()
%make a centered 9x9cm border to circumvent the PE525
%PE525 embroidery machine's insistence on centering
%the data despite off-center bounding box bytes in the 
%converted PES file
border=[128 2 131 131];%131=-12.5 mm, -12.5 mm jump stitch
border=[border border border];%do 3 of these jumps
border=[border 128 2 181 181];%and then a jump by -7.5, -7.5 mm 
%now should be in the lower left corner
border=[border 0 0];%do a stitch
for i=1:9
    border=[border 100 0];%9 regular stitches 10cm in x-direction
end
for i=1:9
    border=[border 0 100];%9 regular stitches 10cm in y-direction
end
for i=1:9
    border=[border 156 0];%9 regular stitches 10cm each in -x direction
end
for i=1:9
    border=[border 0 156];%9 regular stiches 10cm each in -y
end
borderbox=border;
end %end of borderbox subfunction
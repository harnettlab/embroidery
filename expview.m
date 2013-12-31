function x= expview(str)
%Give me a file name in single quotes, I will open a binary file,
%return the x-y data and plot it
%Designed to open and study .exp embroidery files
%CKH 12-20-2013
expfileid=fopen(str);
myread=(fread(expfileid,'uchar'));%read unsigned binary file

%start of design data is first point where x=0
xmin=min(find(myread==0))

x=myread(xmin:end);
wherejump=find(x==128);%here we have jump bytes or color change
%for now, skip those 2 bytes
%note this could miss any escaped data where dx or dy was supposed to be 128

jumpbytes=[wherejump, wherejump+1]; %bytes to ignore for now

normalbytes=setdiff(1:length(x),jumpbytes(:));%bytes to keep, these give dx and dy

x=x(normalbytes);

x(x>128)=x(x>128)-256;%negative dx and dy are represented by 2s complement

xcoords=cumsum(x(1:2:end-1));
ycoords=cumsum(x(2:2:end));
plot(xcoords,ycoords)
hold on
plot(xcoords,ycoords,'r.')%show endpoints with a red dot
axis equal
hold off


%next could create expwrite to write some random spirograph patterns
%figure out escape pattern or just don't use 128 for dx or dy

function[OCTscanparams] = parseHeidelbergRawDataHeader(fname)
%function[OCTscanparams] = ParseHeidelbergRawDataHeader(fname);
%
%read and parse header information in raw data exported from the Heidelberg
%system. called by ReadHeidelbergRawData.
%
%
%
% input args:
% fname - name of .vol raw data file to read
%        %h - header (first 2048 bytes from .vol file)
%
% output args:
%  OCTscanparams - structure of parameters required to read raw data
%    the OCTscanparams struct contains the following fields:
%     .version 
%     .BScanPixelsX - number of horizontal pixels (Ascans) in each Bscan image {SizeX in header}
%     .NumBScans - number of B scans in OCT data {NumBScans in header}
%     .BScanPixelsZ - number of vertical pixels (Ascans samples) in each Bscan image {SizeZ in header}
%     .BScanPixelXmm - width (mm) of Bscan pixel {ScaleX in header}
%     .BScanDistance - distance between B scans (mm) {Distance in header}
%     .BScanPixelZmm - height (mm) of Bscan pixel {ScaleZ in header}
%     .SizeXSlo - # X pixels in the SLO image 
%     .SizeYSlo - # Y pixels in the SLO image
%     .ScaleXSlo 
%     .ScaleYSlo  
%     .FieldSizeSloDegrees  
%     .ScanFocusD 
%     .Eye 
%     .ExamTime integer# of 0.1 microsec units since Jan 1, 1601
%     .ScanPattern 
%     .BScanHdrSize - bytes
%
%
% full specifications of the header are contained in this function file.
%
% (C) Peter Nicholas 8/15/2008


% THE FOLLOWING SPECIFICATION OF THE HEADER STRUCTURE WAS PASTED (AND REFORMATTED FOR ASCII) 
% FROM A PDF FILE THAT SINA EMAILED TO ME
%
% Possible Data Types
% Data Type Description
% byte 8-bit value
% integer 32-bit integer
% float 32-bit IEEE single precision floating point
% double 64-bit IEEE double precision floating point
%
% File Header
% Raw data files begin with a 2048-byte header:
% # Field Name |  Description Data  | 
% ### Type | Length | Offset
% #Version | Version identifier (zero terminated string). Format: “HSF-OCT-xxx” xxx = version number of the file format. Current version: xxx = 100
% ### byte | 12 | 0
% #SizeX | Number of A-Scans in each B-Scan, i.e. the width of each B-Scan in pixel
% ### integer 1 12
% #NumBScans | Number of B-Scans in OCT scan 
% ### integer | 1 | 16
% #SizeZ | Number of samples in an A-Scan, i.e. the Height of each B-Scan in pixel
% ### integer 1 20
% #ScaleX | Width of a B-Scan pixel in mm 
% ### double | 1 | 24
% #Distance | Distance between two adjacent BScans
% ### double 1 32
% #ScaleZ Height of a B-Scan pixel in mm 
% ### double 1 40
% #SizeXSlo Width of the SLO image in pixel 
% ### integer 1 48
% #SizeYSlo | Height of the SLO image in pixel 
% ### integer | 1 | 52
% #ScaleXSlo | Width of a pixel in the SLO image in mm 
% ### double | 1 | 56
% #ScaleYSlo | Height of a pixel in the SLO image in mm
% ### double | 1 | 64
% #FieldSizeSlo | Field size of the SLO image in dgr 
% ### integer | 1 | 72
% #ScanFocus | Scan focus in dpt 
% ### double | 1 | 76
% #ScanPosition | Examined eye (zero terminated string). “OS” for left eye; “OD” for right eye
% ### byte | 4 | 84
% #ExamTime | Examination time. The structure holds an unsigned 64-bit date and time value and represents the number of 100-nanosecond units since the beginning of January 1, 1601.
% ### integer 2 88
% #ScanPattern | Scan pattern type:
% 0 = Unknown pattern
% 1 = Single line scan (1 B-Scan only)
% 2 = Circular scan (1 B-Scan only)
% 3 = Volume scan in ART mode
% 4 = Fast volume scan
% 5 = Radial scan (aka. star pattern)
% ### integer | 1 | 96
% #BScanHdrSize | Size of the Header preceding each BScan in bytes
% ### integer | 1 | 100
% #Spare | Spare bytes for future use. Initialized to 0.
% ### byte 1944 104

fi = fopen(fname,'rb');
if fi==-1, error(['error opening file: ' fname]); end;
%set file pointer to 12 bytes from the beginning of file.
%err = fseek(fi, 12, 'bof'); if err, error(['error setting file pointer to 12 in file:' fname]); end;
temp = fread(fi, 12, 'char');
OCTscanparams.version = char(transpose(temp));
OCTscanparams.BScanPixelsX = fread(fi, 1, 'int32'); %read one 32bit int at current file pointer position.
OCTscanparams.NumBScans = fread(fi, 1, 'int32'); 
OCTscanparams.BScanPixelsZ = fread(fi, 1, 'int32'); 
OCTscanparams.BScanPixelXmm = fread(fi, 1, 'double'); %read one 64bit double at current file pointer position.
OCTscanparams.BScanDistance = fread(fi, 1, 'double'); 
OCTscanparams.BScanPixelZmm = fread(fi, 1, 'double'); 
OCTscanparams.SizeXSlo = fread(fi, 1, 'int32'); 
OCTscanparams.SizeYSlo = fread(fi, 1, 'int32'); 
OCTscanparams.ScaleXSlo = fread(fi, 1, 'double'); 
OCTscanparams.ScaleYSlo = fread(fi, 1, 'double'); 
OCTscanparams.FieldSizeSloDegrees = fread(fi, 1, 'int32'); 
OCTscanparams.ScanFocusD = fread(fi, 1, 'double');
temp = fread(fi, 4, 'char');
OCTscanparams.Eye = char(transpose(temp));
OCTscanparams.ExamTime = fread(fi, 1, 'uint64'); %read 1 unsigned 64bit int (date is ? 2 ints = 1 64bit int?)
OCTscanparams.ScanPattern = fread(fi, 1, 'int32'); 
OCTscanparams.BScanHdrSize = fread(fi, 1, 'int32'); 

fclose(fi);
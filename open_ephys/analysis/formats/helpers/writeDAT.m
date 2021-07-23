function writeDAT(var, filename)
% function writeDAT(var, filename)

dataType = class(var);

fid = fopen(filename, 'w');
fwrite(fid, var, dataType);
fclose(fid);

end
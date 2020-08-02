clear
clc

n = 0:4095;
yn=4095*rectpuls(n,4096);

plot(n,yn);

fid = fopen('./Square_Wave_Rom.coe','wt');

fprintf(fid,'memory_initialization_radix = 10;\nmemory_initialization_vector = ');

 

for i = 1 : 4096

    if mod(i-1,8) == 0 

        fprintf(fid,'\n');

    end

    fprintf(fid,'%4d,',yn(i));

end

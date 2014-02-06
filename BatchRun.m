fileNames{1}='Service_Network_20Object_7-5-2012.out.txt';
fileNames{2}='Albilene_50Object_AllPaths_8-12-12.out.txt';
fileNames{3}='Albilene_50Object_2Paths_8-12-12.out.txt';
fileNames{4}='Albilene_50Object_1Path_8-12-12.out.txt';
fileNames{5}='Albilene_10Object_AllPaths_8-12-12.out.txt';
fileNames{6}='Albilene_10Object_2Paths_8-12-12.out.txt';
fileNames{7}='Albilene_10Object_1Path_8-12-12.out.txt';

for i = 1 : length(fileNames)
    outputfile = fileNames{i};
    ccnsimloaddata;
    ccnsimplotdata;
end
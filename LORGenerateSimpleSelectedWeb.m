%
% refactored from the SuperParsing code
% im_parser/WebsiteGeneration/MakeWeb.m
% http://www.cs.unc.edu/~jtighe/Papers/ECCV10/index.html
%
function LORGenerateSimpleSelectedWeb(SPdata,SPparam)

HOMEWEB = fullfile(SPparam.HOMETESTDATA,'Website');
if ~exist(HOMEWEB,'dir'), mkdir(HOMEWEB); end;

HOMESEMANTICLABEL = SPparam.HOMELABELSETS{1}; % HOMELABELSETS{1} = HOMELABELSETS{labelType}; only SemanticLabels
[~,semanticlabelsFolderName] = fileparts(HOMESEMANTICLABEL);

labelColors = GetColors(SPparam.HOMEDATA,SPparam.SPCODE,SPparam.HOMELABELSETS,SPdata.Labels(SPparam.UseLabelSet));

WebTestList = {'D_','DPwSOR_retSetSize_40_kNN_100_l_0.9_a_3_nIter_3_nStart_100_','DPwSORPotts_retSetSize_40_kNN_100_l_0.9_a_3_nIter_3_nStart_100_beta_0.5_','TigheECCV10'};

maxDim = 1000;

webIndexFile = fullfile(HOMEWEB,'selected.html');
indexFID = fopen(webIndexFile,'w');

fprintf(indexFID,'<!DOCTYPE html>\n');
fprintf(indexFID,'<HTML lang=en xml:lang="en" xmlns="http://www.w3.org/1999/xhtml">\n');

fprintf(indexFID,'<HEAD>\n');
fprintf(indexFID,'<meta http-equiv="content-type" content="text/html; charset=UTF-8">\n');
fprintf(indexFID,'<script type=''text/javascript'' src=''http://code.jquery.com/jquery-1.4.4.min.js''></script>\n\n');

% for checking image size
[folder,onlyName,~] = fileparts(SPdata.testFileList{1});
imLabeled = imread(fullfile(HOMEWEB,semanticlabelsFolderName,WebTestList{1},folder,[onlyName '.png']));
[~,c,~] = size(imLabeled);

fprintf(indexFID,'<STYLE type="text/css">\n');
fprintf(indexFID,'body {\n');
fprintf(indexFID,'\twidth: 100px;\n');
fprintf(indexFID,'}\n');
fprintf(indexFID,'table {\n');
fprintf(indexFID,'\twidth: 500px;\n');
fprintf(indexFID,'}\n');
fprintf(indexFID,'thead tr {\n');
fprintf(indexFID,'\tbackground-color: lightgrey;\n');
fprintf(indexFID,'}\n');
fprintf(indexFID,'.first {\n');
fprintf(indexFID,'\tborder: 1px solid black; vertical-align: top; background-color: white;\n');
fprintf(indexFID,'}\n');
fprintf(indexFID,'#table_container {\n');
fprintf(indexFID,'\tposition:relative;\n');
fprintf(indexFID,'}\n');
fprintf(indexFID,'</STYLE>\n\n');

jsFID = fopen('fixScrollJavascript.js');
tline = fgetl(jsFID);
while ischar(tline)
    fprintf(indexFID,tline);
    fprintf(indexFID,'\n');
    tline = fgetl(jsFID);
end
fclose(jsFID);

fprintf(indexFID,'</HEAD>\n\n');

fprintf(indexFID,'<BODY>\n');
fprintf(indexFID,'<table id="main_table" style="table-layout:fixed; border: 0px solid black;">\n');
fprintf(indexFID,'\t<thead>\n');

fprintf(indexFID,'\t<tr>\n');
fprintf(indexFID,'\t\t<th style="font-size:100%%; width: 200px; background-color: white;">LearingObjRel</th>\n');
fprintf(indexFID,'\t\t<th style="font-size:100%%; width: %dpx;">Original Image</th>\n',c);
for j = 1:length(WebTestList)
    fprintf(indexFID,'\t\t<th style="font-size:100%%; width: %dpx;">',c);
    if length(WebTestList{j}) > 30
        fprintf(indexFID,'%s <br />',WebTestList{j}(1:30));
        fprintf(indexFID,'%s',WebTestList{j}(31:end));
    else
        fprintf(indexFID,'%s',WebTestList{j});
    end;
    fprintf(indexFID,'</th>\n');
end;
fprintf(indexFID,'\t</tr>\n');
fprintf(indexFID,'\t</thead>\n');

pfig = ProgressBar('Generating Web');
range = 1:length(SPdata.testFileList);

for i = range
    fprintf(indexFID,'\t<tr>\n');
    im = imread(fullfile(SPparam.HOMEIMAGES,SPdata.testFileList{i}));
    [r,~,~] = size(im);
    
    [folder,onlyName,ext] = fileparts(SPdata.testFileList{i});
    
    localImageFile = fullfile(HOMEWEB,'Images',folder,[onlyName ext]);
    if ~exist(fileparts(localImageFile),'dir'), mkdir(fileparts(localImageFile)); end;
    copyfile(fullfile(SPparam.HOMEIMAGES,SPdata.testFileList{i}),localImageFile,'f');
    
    % name
    fprintf(indexFID,'\t\t<td class="first" style="tbackground-color: white;">%s</td>\n',onlyName);
    
    % original image
    fprintf(indexFID,'\t\t<td style="width: %dpx;">\n',c);
    fprintf(indexFID,'\t\t\t<center><img height="%d" src="%s"></center>\n',min(r,maxDim),['Images/' folder '/' onlyName ext]);
    fprintf(indexFID,'\t\t</td>\n');
    
    for j = 1:length(WebTestList)
        resultFile = fullfile(SPparam.HOMETESTDATA,'LearningObjRel',semanticlabelsFolderName,WebTestList{j},folder,[onlyName '.mat']);
        resultCache = [resultFile '.cache'];
        if exist(resultCache,'file')
            load(resultCache,'-mat'); % metaData perLabelStat(#labelsx2) perPixelStat([# pix correct, # pix total]);
        end;
        
        fprintf(indexFID,'\t\t<td style="font-size:100%%;">\n');
        fprintf(indexFID,'\t\t\t<img height="%d" src="%s">\n',min(r,maxDim),[semanticlabelsFolderName '/' WebTestList{j} '/' folder '/' onlyName '.png']);
        
        if exist('perPixelStat','var')
            fprintf(indexFID,'<br /><center>%.1f%%</center>\n',100*perPixelStat(1)/perPixelStat(2));
        end;
        
        fprintf(indexFID,'\t\t</td>\n');
    end;
    
    fprintf(indexFID,'\t</tr>\n');
    ProgressBar(pfig,find(range==i),length(range));
end;

close(pfig);
fprintf(indexFID,'</table>\n');
fprintf(indexFID,'</BODY>\n');
fprintf(indexFID,'</HTML>');
fclose(indexFID);

return;
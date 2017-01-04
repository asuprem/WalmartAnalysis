%% Import data for cluster analysis
% Data has been clustered by NNcluster
% perform covariance analysis, etc, to find product relations

load('prodTextToNo.mat');
%% Initialize variables.
for fileCount=1:6
filename = ['C:\Users\Abhijit\OneDrive - Columbia University\Work+Projects\Hackathon\Walmart\clustered\trainByCluster_a' num2str(fileCount) '.csv'];
delimiter = ',';
startRow = 2;

%% Format string for each line of text:
%   column2: double (%f)
%	column3: double (%f)
%   column4: text (%q)
%	column5: double (%f)
%   column6: double (%f)
%	column7: double (%f)
%   column8: double (%f)
%	column9: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%*q%f%f%q%f%f%f%f%f%*s%*s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Create output variable
dataArray([1, 2, 4, 5, 6, 7, 8]) = cellfun(@(x) num2cell(x), dataArray([1, 2, 4, 5, 6, 7, 8]), 'UniformOutput', false);
currClust = [dataArray{1:end-1}];
%% Clear temporary variables
clearvars filename delimiter startRow formatSpec fileID dataArray ans;

%% Convert clusters to MATLAB readable
clust = zeros(size(currClust,1),size(currClust,2));
clust(:,1:7) = cell2mat(currClust(:,[1 2 4:8]));
clust(:,8)=datenum(currClust(:,3));

%% Date sampling
[dt, I]=sort(clust(:,8));
clustN = clust(I,[3 8]);

%% Postprocess to remove NaNs, etcs
cD=clustN(1,2);
currPr = clustN(1,1);
prRoot(fileCount).prList = [];
for ct=2:size(clustN,1)
    if(clustN(ct,2)==cD)
        if(~isnan(clustN(ct,1)))
            currPr=currPr+clustN(ct,1);
        end
    else
        prRoot(fileCount).prList(length(prRoot(fileCount).prList)+1)=currPr;
        currPr = clustN(ct,1);
        cD=clustN(ct,2);
    end
end

%% Covariance finding, mapping, 
clustN = clust(I,[2 3 8]);
%clustN(:,1)=prodTextToNo(clustN(:,1),2)+1;

clustN(:,3)=clustN(:,3)-clustN(1,3)+1;
maxX = max(clustN(:,1));
maxY = max(clustN(:,3));
covM = zeros(maxX,maxY);

for a=1:size(clustN,1)
   covM(clustN(a,1),clustN(a,3))=clustN(a,2);
   if(isnan(clustN(a,2)))
       covM(clustN(a,1),clustN(a,3))=0;
   end
end

prRoot(fileCount).covM=corrcoef((covM+0.001*min(min(covM)))');
prRoot(fileCount).covSum = sum(abs(prRoot(fileCount).covM),2);
%prRoot(fileCount).covM(prRoot(fileCount).covM==1)=0;
%prRoot(fileCount).covM = round(prRoot(fileCount).covM);

end


%% ProdPlotting

%%% Sales
figure(1)
for count=1:6
   subplot(3,2,count)
   plot(prRoot(count).prList);
   xlabel('Days');
   ylabel('Sales');
   title(['Sales for A cluster ' num2str(count)]);
   grid on;   
   sav=['corrA.clust' num2str(count) '.sales.csv'];
   csvwrite(sav,prRoot(count).prList);
end

%%% Covariance for each cluster
figure(2)
for count=1:6
   subplot(3,2,count)
   plot(prRoot(count).covSum/max(prRoot(count).covSum));
   xlabel('PrID');
   ylabel('Covariance');
   title(['Covariance for A cluster ' num2str(count)]);
   grid on;   
   sav=['corrA.clust' num2str(count) '.covariance.csv'];
    csvwrite(sav,prRoot(count).covM);
end

%%% Correlation between sub-clusters within the cluster
figure(3);toPlot=[1 3 4 5];
for count=1:4
subplot(2,2,count);
covCt=find(prRoot(toPlot(count)).covSum/max(prRoot(toPlot(count)).covSum)>.95);
plot(prRoot(toPlot(count)).covM(covCt,:)');
legend(num2str(covCt));
xlabel('Prod ID');
ylabel('Correlation');sav=['corrA.clust' num2str(toPlot(count)) '.prods' regexprep(num2str(covCt'), '\s\s', '.') '.csv'];
title(['A Cluster ' num2str(toPlot(count))]);
csvwrite(sav,prRoot(toPlot(count)).covM(covCt,:));
end



%% Temporal Information (Unneeded)
% figure(4);
% for count=1:6
% covCt=find(prRoot(count).covSum/max(prRoot(count).covSum)>.95);
% prodDates = clustN(ismember(clustN(:,1),covCt),[2,3]);
% subplot(3,2,count);
% plot(prodDates(:,2),prodDates(:,1));
% legend(num2str(covCt));
% xlabel('Dates');
% ylabel('Sales');
% end
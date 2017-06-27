% Parameters

expid = 'exp_DTSmodels_01';
snapshotGroups = { [5,6,7], [18,19,20] };
errorCol = 'rde2'; % 'rdeM1_M2WReplace'; % 'rdeValid';
nTrainedCol = 'nTrained2';
plotImages = true;
aggFcn = @(x) quantile(x, 0.75);

% Loading the data
if (~exist('resultTableAgg', 'var'))
  load(['exp/experiments/' expid '/modelStatistics.mat']);
end
run(['exp/experiments/' expid '.m']);

% Clear the non-interesting settings: trainRange == 1.5 OR trainsetSizeMax == 5*dim
modelOptions.trainRange(1) = [];
modelOptions.trainsetSizeMax(1) = [];

% Processing model options
nSnapshotGroups = length(snapshotGroups);
multiFieldNames = getFieldsWithMultiValues(modelOptions);
modelOptions_fullfact = combineFieldValues(modelOptions);
hashes = cellfun(@(x) modelHash(x), modelOptions_fullfact, 'UniformOutput', false);

% Model settings differences
modelsSettings = cell(length(hashes), length(multiFieldNames));
for mi = 1:length(hashes)
  modelsSettings(mi, 1:2) = {mi, hashes{mi}};
  for mf = 1:length(multiFieldNames)
    modelsSettings{mi, 2+mf} = modelOptions_fullfact{mi}.(multiFieldNames{mf});
  end
end

tModelsSettings = cell2table(modelsSettings, 'VariableNames', [{'id', 'hash'}, multiFieldNames]);
settingsToDelete = tModelsSettings{ ...
    tModelsSettings.trainRange == 1.5 | strcmpi(tModelsSettings.trainsetSizeMax, '5*dim'), ...
    'hash'};

% Initialization
modelErrorRanksPerFS = cell(length(dimensions), 1);
modelErrorRanks = zeros(length(hashes), length(dimensions));
modelErrors = zeros(length(hashes), length(dimensions));
bestModelNumbers = zeros(length(hashes), length(dimensions));
bestModelRankNumbers = zeros(length(hashes), length(dimensions));
for di = 1:length(dimensions)
  modelErrorRanksPerFS{di} = zeros(length(hashes), length(functions) * nSnapshotGroups);  
end

% Column names
modelErrorsColNames = cell(length(functions)*nSnapshotGroups, 1);
for fi = 1:length(functions)
  fun = functions(fi);
  for si = 1:nSnapshotGroups
    iCol = (fi-1)*nSnapshotGroups + si;
    modelErrorsColNames{iCol} = ['f' num2str(fun) '_S' num2str(si)];
  end
end

% Loading errors from the table
if (~exist('modelErrorsPerFS', 'var'))
  modelErrorsPerFS = cell(length(dimensions), 1);

  for di = 1:length(dimensions)
    dim = dimensions(di);
    fprintf('%dD: ', dim);
    modelErrorsPerFS{di} = zeros(length(hashes), length(functions) * nSnapshotGroups);

    for mi = 1:length(hashes)
      hash = hashes{mi};
      fprintf('model %s ', hash);

      for fi = 1:length(functions)
        fun = functions(fi);
        % fprintf('f%d ', fun);

        for si = 1:nSnapshotGroups

          iCol = (fi-1)*nSnapshotGroups + si;
          % modelErrorsPerFS{di}(mi, iCol) = resultTableAgg{ ...
          %     strcmpi(resultTableAgg.hash, hash) ...
          %     &  resultTableAgg.dim == dim ...
          %     &  resultTableAgg.fun == fun ...
          %     &  resultTableAgg.snpGroup == si, errorCol};

          modelErrorsPerFS{di}(mi, iCol) = aggFcn(resultTableAll{ ...
              strcmpi(resultTableAll.hash, hash) ...
              &  ismember(resultTableAll.snapshot, snapshotGroups{si}) ...
              &  resultTableAll.dim == dim ...
              &  resultTableAll.fun == fun, errorCol});
        end  % for snapshotGroups

      end  % for functions

      fprintf('\n');
    end  % for models
  end
end

% Loading # of successful trains from the table
if (~exist('trainSuccessPerFS', 'var'))
  trainSuccessPerFS = cell(length(dimensions), 1);

  for di = 1:length(dimensions)
    dim = dimensions(di);
    fprintf('%dD: ', dim);
    trainSuccessPerFS{di} = zeros(length(hashes), length(functions) * nSnapshotGroups);

    for mi = 1:length(hashes)
      hash = hashes{mi};
      fprintf('model %s ', hash);

      for fi = 1:length(functions)
        fun = functions(fi);
        % fprintf('f%d ', fun);

        for si = 1:nSnapshotGroups

          iCol = (fi-1)*nSnapshotGroups + si;
          trainSuccessPerFS{di}(mi, iCol) = resultTableAgg{ ...
              strcmpi(resultTableAgg.hash, hash) ...
              &  resultTableAgg.dim == dim ...
              &  resultTableAgg.fun == fun ...
              &  resultTableAgg.snpGroup == si, nTrainedCol} ...
              / (length(snapshotGroups{si})*length(instances));
        end  % for snapshotGroups
      end  % for functions
      fprintf('\n');
    end  % for models
  end
end


% Summarizing results
woF5 = [1:8, 11:48];
for di = 1:length(dimensions)
  for col = woF5
    modelErrorRanksPerFS{di}(:, col) = ranking(modelErrorsPerFS{di}(:, col));
  end
  modelErrors(:, di) = nansum(modelErrorsPerFS{di}(:, woF5), 2) ./ (length(woF5));
  modelErrorRanks(:, di) = nansum(modelErrorRanksPerFS{di}(:, woF5), 2) ./ (length(woF5));
  modelErrorsDivSuccess(:, di) = nansum(modelErrorsPerFS{di}(:, woF5) ...
      ./ trainSuccessPerFS{di}(:, woF5), 2) ./ (length(woF5));
  modelErrorDivSuccessRanks(:, di) = nansum(modelErrorRanksPerFS{di}(:, woF5) ...
      ./ trainSuccessPerFS{di}(:, woF5), 2) ./ (length(woF5));  
  % Normlize to (0, 1)
  % modelErrors(:, di) = (modelErrors(:, di) - min(modelErrors(:, di))) ./ (max(modelErrors(:, di)) - min(modelErrors(:, di)));
  [~, bestModelNumbers(:, di)] = sort(modelErrorsDivSuccess(:, di));
  [~, bestModelRankNumbers(:, di)] = sort(modelErrorDivSuccessRanks(:, di));
end  % for dimensions

if (plotImages)
  for di = 1:length(dimensions)
    dim = dimensions(di);
    figure();
    image(modelErrorsPerFS{di}(:, woF5) ./ trainSuccessPerFS{di}(:, woF5), 'CDataMapping', 'scaled');
    colorbar;
    ax = gca();
    ax.XTick = 1:2:length(woF5);
    ax.XTickLabel = ceil(woF5(1:2:end) ./ nSnapshotGroups);
    % ax.XTickLabel = cellfun(@(x) regexprep(x, '_.*', ''), modelErrorsColNames(woF5), 'UniformOutput', false);
    title([num2str(dim) 'D']);
    xlabel('functions and snapshot groups');
  end
  
  figure();
  image(modelErrorsDivSuccess, 'CDataMapping', 'scaled');
  colorbar;
  ax = gca();
  ax.XTick = 1:length(dimensions);
  ax.XTickLabel = dimensions;
  title('Average normalized RDE');
  xlabel('dimension');
end

% Prepare Anova-n categorical predictors
categorical = { modelsSettings(:, 3), cell2mat(modelsSettings(:, 4)), ...
    cellfun(@(x) str2num(regexprep(x, '\*.*', '')), ...
    modelsSettings(:, 5)), modelsSettings(:, 6)};

% [p,tbl,stats,terms] = anovan(modelErrors(:, 1), categorical, 'model', 1, 'varnames', multiFieldNames);
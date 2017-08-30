classdef PolynomialModel < WeakModel
  
  properties %(Access = protected)
    modelSpec % model specification (https://www.mathworks.com/help/stats/fitlm.html#inputarg_modelspec)
    coeff % coefficients
    coeffCov % coefficient covariance
    features % used features
  end
  
  methods
    function obj = PolynomialModel(modelOptions)
      % constructor
      obj = obj@WeakModel(modelOptions);
      % specific model options
      obj.modelSpec = defopts(modelOptions, 'modelSpec', 'constant');
    end

    function obj = trainModel(obj, X, y)
      % train the model based on the data (X,y)
      XP = generateFeatures(X, obj.modelSpec, true);
      M = XP' * XP;
      % check rank deficiency
      r = rank(M);
      if r < size(M, 2)
        % remove dependent columns
        [~, obj.features] = rref(M);
        XP = XP(:, obj.features);
        M = M(obj.features, obj.features);
      end
      %warning('off', 'MATLAB:rankDeficientMatrix');
      %warning('off', 'MATLAB:singularMatrix');
      %warning('off', 'MATLAB:nearlySingularMatrix');
      Mi = pinv(M);
      %obj.coeff = Mi * XP' * y;
      %obj.coeff = M \ (XP' * y);
      obj.coeff = XP \ y;
      %warning('on', 'MATLAB:rankDeficientMatrix');
      %warning('on', 'MATLAB:singularMatrix');
      %warning('on', 'MATLAB:nearlySingularMatrix');
      yPred = XP * obj.coeff;
      % var(b) = E(b^2) * (X'*X)^-1
      obj.coeffCov = (mean((y - yPred).^2)) * Mi;
    end
    
    function [yPred, sd2, ci] = modelPredict(obj, X)
      % predicts the function values in new points X
      XP = generateFeatures(X, obj.modelSpec, true);
      if ~isempty(obj.features)
        XP = XP(:, obj.features);
      end
      [yPred] = XP * obj.coeff;
      if nargout >= 2
        % sd2 = diag(XP * obj.coeffCov * XP');
        sd2 = sum(XP * obj.coeffCov .* XP, 2);
        if nargout >= 3
          ci = varToConfidence(yPred, sd2);
        end
      end
    end
  end
  
end


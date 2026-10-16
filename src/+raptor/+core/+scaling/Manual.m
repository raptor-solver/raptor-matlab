classdef Manual < raptor.core.scaling.CompositeLinearScaling
    %MANUAL Summary of this class goes here
    %   Detailed explanation goes here

    properties (Access = protected)
        phaseScales
    end 

    methods
        function obj = Manual(cfg, previousScaling)
            % superclass constructor
            if nargin == 0
                super_args = {};
            elseif nargin == 1
                super_args = {cfg};
            elseif nargin == 2
                super_args = {cfg, previousScaling};
            end
            obj@raptor.core.scaling.CompositeLinearScaling(super_args{:});

            if nargin >= 1
                obj.phaseScales = cfg;
            end
        end

        function build(obj, transcription, trajectories)
            % method that builds the linear scaling matrices according to
            % the specified manual scaling values

            % assemble the identity scaling matrices
            J0 = transcription.getJacobian(...
                transcription.getGlobalVariable(trajectories.initialGuess));
            A = speye(size(J0, 2));
            B = speye(size(J0, 1));
            D = 1;

            % loop over all phases
            for truePhase = transcription.ocp.phases
                idx = truePhase.idx;
                setPhase = obj.phaseScales.(obj.phaseScales.phaseNames(idx));

                % loop over all fields in the current phase setting
                setNames = string(fieldnames(setPhase));
                allowedNames = obj.getValidFieldNames(truePhase, transcription);
                for field = setNames(:)'

                    % skip the fields with no specified scaling
                    if isempty(setPhase.(field))
                        continue
                    end

                    % check that the current field matches a quantity
                    % for this phase
                    if ~ismember(field, allowedNames)
                        raptor.core.utils.Logger.err_manualScalingSettingsNotFound(...
                            idx, field, allowedNames);
                    end

                    % check that the size of the current field matches
                    % the one specified in the problem
                    correctSize = obj.getCorrectFieldSize(field, truePhase);
                    if length(setPhase.(field)) ~= correctSize
                        raptor.core.utils.Logger.err_manualScalingSettingsSizeMismatch(...
                            idx, field, length(setPhase.(field)), correctSize);
                    end

                    % correct the field scales to remove 0 and
                    % infs/nans
                    currentScales = 1 ./ setPhase.(field)(:);
                    currentScales(currentScales == 0) = 1;
                    currentScales(~isfinite(currentScales)) = 1;

                    % get the indexes in the corresponding
                    % transcription
                    currentIdxs = obj.getCorrrectIndexes(field, transcription, truePhase);
                    nRepetitions = length(currentIdxs) / correctSize;

                    % update the correct linear scaling matrix
                    if ismember(field, ["time" "states" "controls" ...
                            "localParameters" "globalParameters"])
                        A(currentIdxs, currentIdxs) = diag(repmat(currentScales, nRepetitions, 1));
                    elseif field == "cost"
                        D = currentScales;
                    else
                        B(currentIdxs, currentIdxs) = diag(repmat(currentScales, nRepetitions, 1));
                    end
                end

                % assign linear scaling matrices
                obj.A = A; obj.A_inv = inv(A);
                obj.B = B; obj.B_inv = inv(B);
                obj.D = D; obj.D_inv = inv(D);
                obj.b = zeros(size(A, 1), 1); obj.b_inv = obj.b;
            end
        end


    end

    methods (Hidden, Static)
        function fNames = getValidFieldNames(phase, transcription)
            % method that returns the string array corresponding to the
            % full list of valid field names that can be found in the
            % settings phase struct

            % default names
            fNames = ["time" "states" "controls" "localParameters" ...
                "globalParameters" "cost"];

            % constraints for the current phase
            cNames = string(fieldnames(transcription.con_idx(phase.idx)));
            fNames = [fNames cNames(:)'];
        end

        function sz = getCorrectFieldSize(fName, phase)
            % function that outputs the correct size for the specified
            % field as stored in the core problem representation

            % default variable sizes
            if fName == "time" || fName == "cost"
                sz = 1;
            elseif fName == "states"
                sz = phase.nStates;
            elseif fName == "controls"
                sz = phase.nControls;
            elseif fName == "localParameters"
                sz = phase.nLocalParameters;
            elseif fName == "globalParameters"
                sz = phase.nGlobalParameters;
            else
                % constraints
                for con = phase.constraints
                    if con.name == fName
                        sz = con.outputDim;
                    end
                end
            end
        end

        function idxs = getCorrrectIndexes(fName, transcription, phase)
            % function that returns the correct indexes in the transcribed
            % nlp vectors

            % default variable indexes
            if fName == "cost"
                idxs = 1;
            elseif fName == "time"
                idxs = [transcription.var_idx(phase.idx).initialTime ...
                    transcription.var_idx(phase.idx).finalTime];
            elseif fName == "states"
                idxs = transcription.var_idx(phase.idx).discretized.states;
            elseif fName == "controls"
                idxs = transcription.var_idx(phase.idx).discretized.controls;
            elseif fName == "localParameters"
                idxs = transcription.var_idx(phase.idx).localParameters;
            elseif fName == "globalParameters"
                idxs = transcription.var_idx(phase.idx).globalParameters;
            else
                % constraints
                idxs = transcription.con_idx(phase.idx).(fName);
            end
        end
    end
end


classdef Logger
    % Logger  Logging class for all raptor routines
    %
    %   Logger provides the unified interface to display messages generated
    %   by raptor routines, including information, warnings, and errors.
    %   The class also provides an interface to log iteration data for
    %   specific solvers.
    %
    %
    % -------------------------------------------------------------------------
    % VERBOSITY:
    %   The verbosity level defines the amount of information printed to
    %   screen (0 = errs; 1 = errs, warns; 2 = errs, warns, info; 3 = errs,
    %   warns, info with timestamps). Errors are always raised, whatever the
    %   level. The default level is 2.
    %
    % METHODS:
    %   setVerbosity(level)     - set the verbosity level of the session
    %
    %   level = verbosity()     - get the current verbosity level
    %
    %   info(msg, varargin)     - display info message with format msg and
    %   related data, if any
    %
    %   warn(ID, msg, varargin) - display warning message with format msg
    %   and related data, if any
    %
    %   err(ID, msg, varargin)  - raise an error with format msg and
    %   related data, if any
    %
    % -------------------------------------------------------------------------
    % USAGE:
    %   raptor.core.utils.Logger.info("Collocated problem into grid with %d nodes",
    %   N_nodes)
    %   raptor.core.utils.Logger.setVerbosity(1)   % warnings and errors only
    %
    % -------------------------------------------------------------------------
    % NOTES:
    %   - All methods are static, so the logger can be called from anywhere
    %   within the raptor routines without requiring an instance. The
    %   verbosity level is therefore stored at session level (in the
    %   RAPTOR_VERBOSITY environment variable, which survives "clear all"),
    %   and is normally set through RAPTOR_init.
    %
    % -------------------------------------------------------------------------
    % SEE ALSO:
    %

    properties (Constant, Hidden)
        % default verbosity level, used until a level is set
        defaultVerbosity = 2
    end

    methods (Static)
        function setVerbosity(level)
            % set the verbosity level for the rest of the matlab session
            arguments
                level (1, 1) {mustBeInteger, mustBeInRange(level, 0, 3)}
            end
            setenv("RAPTOR_VERBOSITY", string(level));
        end

        function level = verbosity()
            % get the verbosity level of the session, falling back to the
            % default one when it was never set or holds an invalid value
            level = str2double(getenv("RAPTOR_VERBOSITY"));
            if ~ismember(level, 0 : 3)
                level = raptor.core.utils.Logger.defaultVerbosity;
            end
        end

        function info(msg, varargin)
            % check verbosity level and assign proper splash string
            level = raptor.core.utils.Logger.verbosity();
            if level == 3
                splash = [char(datetime("now")), ' [RAPTOR INFO]>>'];
            elseif level >= 2
                splash = '[RAPTOR INFO]>>';
            else
                splash = 0;
            end

            % print only if needed
            if splash, fprintf([splash ' %s\n'], sprintf(msg, varargin{:})); end
        end

        function warn(ID, msg, varargin)
            % check verbosity level and assign proper splash string
            level = raptor.core.utils.Logger.verbosity();
            if level == 3
                splash = [char(datetime("now")), ' [RAPTOR WARN]>>'];
            elseif level >= 1
                splash = '[RAPTOR WARN]>>';
            else
                splash = 0;
            end

            % print only if needed
            if splash, warning(['RAPTOR:', char(ID)], [splash ' %s\n'], sprintf(msg, varargin{:})); end
        end

        function err(ID, msg, varargin)
            % errors are raised at every verbosity level, which only
            % decides whether the message carries a timestamp
            if raptor.core.utils.Logger.verbosity() == 3
                splash = [char(datetime("now")), ' [RAPTOR ERR!]>>'];
            else
                splash = '[RAPTOR ERR!]>>';
            end
            error(['RAPTOR:', char(ID)], [splash ' %s\n'], sprintf(msg, varargin{:}));
        end

        % predefined errors
        errNoVariableMatch(phaseName, varName)
        errSizeMismatch(phaseName, type, var, dim, refDim)
        errDuplicateName(phaseName, property, name)
        errNotAColumn(phaseName, varName, size1, size2)
        errUndefinedProperty(phaseName, property)
        errTestFunctionEvaluation(phaseName, funcName, errMessage)
        errUndefinedCollocationProperty(attemptedProperty, requiredProperty)

        err_interPhaseMismatch(phase1Name, phase2Name, whichVar)
        err_valueNotAssigned(phaseName, propName, varName)
        err_inconsistentLength(phaseName, varName1, varName2)
        err_inconsistentBounds(phaseName, whichBound, whichVar, whyInconsistent)
        err_testEvaluationFailed(ME, phaseName, constraintName)
        err_manualScalingSettingsNotFound(phaseIdx, settingsPropertyName, validPropertyNames)
        err_manualScalingSettingsSizeMismatch(phaseIdx, settingsPropertyName, settingsPropertySize, truePropertySize)
        err_worhpUnavailable(problems)
        err_worhpSolverFailure(ME, session)
        err_operatorRequiresPathFunction(operatorName, baseFunction)

        % predefined warnings
        warnOverwritingProperty(phaseName, propertyName, newVar, oldVar)
        warnUndefinedProperty(phaseName, property)

        warn_rethrowErrAsWarn(ME)
        warn_failedPostProcessing(ME, whichStep)
    end
end

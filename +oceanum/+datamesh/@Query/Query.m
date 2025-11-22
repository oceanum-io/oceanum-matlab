classdef Query < handle
    %QUERY - Encapsulate parameters and filters for a data query
    %   Q = QUERY() creates an empty query object. Fields represent datasource,
    %   selection variables and various filters (time, geo, level, coord).
    %   Useful helpers generate canonical filter structs.
    properties
        datasource
        parameters
        description
        variables
        timefilter
        geofilter
        levelfilter
        coordfilter
        crs
        aggregate
        functions
        limit
        id
    end
    
    methods
        function obj = Query(varargin)
          % QUERY - Construct a Query object from struct or name-value pairs
          %
          % Input arguments:
          % varargin - either a single struct describing the object or name-value pairs
          %
          % Output arguments:
          % obj      - initialized Query object
            arguments (Repeating)
                varargin
            end
            
            % Parse input arguments
            if nargin >= 1
                if isstruct(varargin{1})
                    % Input is a struct
                    s = varargin{1};
                    obj.setFromStruct(s);
                elseif ischar(varargin{1}) || isstring(varargin{1})
                    % Parse name-value pairs into expected properties
                    p = inputParser;
                    addParameter(p, 'datasource', '', @(x) ischar(x) || isstring(x));
                    addParameter(p, 'parameters', struct(), @isstruct);
                    addParameter(p, 'description', '', @(x) ischar(x) || isstring(x));
                    addParameter(p, 'variables', {}, @iscell);
                    addParameter(p, 'timefilter', struct.empty, @isstruct);
                    addParameter(p, 'geofilter', struct.empty, @isstruct);
                    addParameter(p, 'levelfilter', struct.empty, @isstruct);
                    addParameter(p, 'coordfilter', {}, @iscell);
                    addParameter(p, 'crs', '', @(x) ischar(x) || isstring(x) || isnumeric(x));
                    addParameter(p, 'aggregate', struct.empty, @isstruct);
                    addParameter(p, 'functions', {}, @iscell);
                    addParameter(p, 'limit', [], @isnumeric);
                    addParameter(p, 'id', '', @(x) ischar(x) || isstring(x));
                    
                    parse(p, varargin{:});
                    
                    obj.datasource = p.Results.datasource;
                    obj.parameters = p.Results.parameters;
                    obj.description = p.Results.description;
                    obj.variables = p.Results.variables;
                    obj.timefilter = p.Results.timefilter;
                    obj.geofilter = p.Results.geofilter;
                    obj.levelfilter = p.Results.levelfilter;
                    obj.coordfilter = p.Results.coordfilter;
                    obj.crs = p.Results.crs;
                    obj.aggregate = p.Results.aggregate;
                    obj.functions = p.Results.functions;
                    obj.limit = p.Results.limit;
                    obj.id = p.Results.id;
                end
            end
        end
        
        function setFromStruct(obj, s)
            if isfield(s, 'datasource')
                obj.datasource = s.datasource;
            end
            if isfield(s, 'parameters')
                obj.parameters = s.parameters;
            end
            if isfield(s, 'description')
                obj.description = s.description;
            end
            if isfield(s, 'variables')
                obj.variables = s.variables;
            end
            if isfield(s, 'timefilter')
                obj.timefilter = s.timefilter;
            end
            if isfield(s, 'geofilter')
                obj.geofilter = s.geofilter;
            end
            if isfield(s, 'levelfilter')
                obj.levelfilter = s.levelfilter;
            end
            if isfield(s, 'coordfilter')
                obj.coordfilter = s.coordfilter;
            end
            if isfield(s, 'crs')
                obj.crs = s.crs;
            end
            if isfield(s, 'aggregate')
                obj.aggregate = s.aggregate;
            end
            if isfield(s, 'functions')
                obj.functions = s.functions;
            end
            if isfield(s, 'limit')
                obj.limit = s.limit;
            end
            if isfield(s, 'id')
                obj.id = s.id;
            end
        end
        
        function s = toStruct(obj)
            s = struct();
            
            props = properties(obj);
            for i = 1:length(props)
                propName = props{i};
                propValue = obj.(propName);
                if ~isempty(propValue)
                    s.(propName) = propValue;
                end
            end
        end
        
        function json = toJson(obj)
            s = obj.toStruct();
            json = jsonencode(s);
        end
        
        function str = char(obj)
            str = sprintf('Query for datasource: %s', obj.datasource);
            if ~isempty(obj.description)
                str = sprintf('%s\nDescription: %s', str, obj.description);
            end
            if ~isempty(obj.variables)
                if iscell(obj.variables)
                    vars = strjoin(obj.variables, ', ');
                else
                    vars = jsonencode(obj.variables);
                end
                str = sprintf('%s\nVariables: %s', str, vars);
            end
            if ~isempty(obj.limit)
                str = sprintf('%s\nLimit: %d', str, obj.limit);
            end
        end
        
        function disp(obj)
            fprintf('%s\n', char(obj));
        end
        
        function tf = hasFilters(obj)
            % Check if query has any filters applied
            tf = ~isempty(obj.timefilter) || ~isempty(obj.geofilter) || ...
                 ~isempty(obj.levelfilter) || ~isempty(obj.coordfilter) || ...
                 ~isempty(obj.variables) || ~isempty(obj.limit);
        end
    end
    
    methods (Static)
        function timefilter = createTimeFilter(times, type, resolution, resample)
          % CREATETIMEFILTER - Build a simple time-filter descriptor struct
          %
          % Input arguments:
          % times      - time values or interval to filter on
          % type       - 'range' (default) or other filter type
          % resolution - time resolution, 'native' by default
          % resample   - resampling method, 'linear' by default
          % 
          % Note: Helper method to create time filter
            arguments
                times
                type {mustBeTextScalar} = 'range'
                resolution {mustBeTextScalar} = 'native'
                resample {mustBeTextScalar} = 'linear'
            end
            
            timefilter = struct();
            timefilter.type = type;
            timefilter.times = times;
            timefilter.resolution = resolution;
            timefilter.resample = resample;
        end
        
        function geofilter = createGeoFilter(geom, type, interp, resolution, alltouched)
            % Helper method to create geo filter
            arguments
                geom
                type {mustBeTextScalar} = 'bbox'
                interp {mustBeTextScalar} = 'linear'
                resolution double = 0.0
                alltouched logical = false
            end
            
            geofilter = struct();
            geofilter.type = options.type;
            geofilter.geom = geom;
            geofilter.interp = options.interp;
            geofilter.resolution = options.resolution;
            geofilter.alltouched = options.alltouched;
        end
        
        function levelfilter = createLevelFilter(levels, varargin)
            % Helper method to create level filter
            arguments
                levels
                options.type {mustBeTextScalar} = 'range'
                options.interp {mustBeTextScalar} = 'linear'
            end
            
            levelfilter = struct();
            levelfilter.type = options.type;
            levelfilter.levels = levels;
            levelfilter.interp = options.interp;
        end
    end
end
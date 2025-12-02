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
        function obj = Query(query_)
            % QUERY - Construct a Query object from struct or name-value pairs
            %
            % Input arguments:
            % query_ - either a single struct describing the object or name-value pairs
            %
            % Output arguments:
            % obj      - initialized Query object
            arguments (Repeating)
                query_
            end
            if isfield(query_,"datasource")
                
            end
            
        end
        
        function setFromStruct(obj, s)
            % SETFROMSTRUCT - Populate object fields from a structure when present
            %
            % Input arguments:
            % s - structure possibly containing any subset of object fields
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
            % TOSTRUCT - Convert object to struct, omitting empty properties
            %
            % Input arguments:
             % obj - object whose public properties will be exported
            %
            % Output arguments:
            % s   - struct containing non-empty property name/value pairs
            s = struct();
            
            props = properties(obj);
            % Iterate over all public properties and copy non-empty ones
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
            geofilter.type = type;
            geofilter.geom = geom;
            geofilter.interp = interp;
            geofilter.resolution = resolution;
            geofilter.alltouched = alltouched;
        end
        
        function levelfilter = createLevelFilter(levels, type, interp)
            % Helper method to create level filter
            arguments
                levels
                type {mustBeTextScalar} = 'range'
                interp {mustBeTextScalar} = 'linear'
            end
            
            levelfilter = struct();
            levelfilter.type = type;
            levelfilter.levels = levels;
            levelfilter.interp = interp;
        end


        %% Helper functions
        
        function dt = parse_time(v)
        % parse_time Convert input to MATLAB datetime (UTC or naive)
            if isempty(v)
                dt = [];
                return
            end
            if isa(v,'datetime')
                dt = v;
                if isempty(dt.TimeZone)
                    % naive: treat as UTC then remove timezone to mimic pandas behavior
                    dt.TimeZone = 'UTC';
                end
                try
                    % convert to naive by clearing timezone
                    dt.TimeZone = '';
                catch
                    % older MATLAB versions may not support clearing; ignore
                end
                return
            end
            if ischar(v) || isstring(v)
                s = char(v);
                % Try ISO8601 general parse, prefer automatic parsing
                try
                    dt = datetime(s,'InputFormat','yyyy-MM-dd''T''HH:mm:ss','TimeZone','UTC');
                catch
                    try
                        dt = datetime(s,'TimeZone','UTC');
                    catch ME
                        error('parse_time:Format','Timestamp format not valid: %s', ME.message);
                    end
                end
                try
                    dt.TimeZone = '';
                catch
                end
                return
            end
            error('parse_time:Type','datetime or time string required');
        end
        
        function dur = parse_timedelta(v)
        % parse_timedelta Convert various inputs to MATLAB duration
            if isempty(v)
                dur = [];
                return
            end
            if isa(v,'duration')
                dur = v;
                return
            end
            if isnumeric(v)
                % treat numeric as seconds
                dur = seconds(v);
                return
            end
            if ischar(v) || isstring(v)
                s = strtrim(char(v));
                % attempt hh:MM:SS or days like '2D'
                try
                    dur = duration(s);
                    return
                catch
                    % attempt day format 'Nd' or 'Nday' or 'N D'
                    tok = regexp(s,'^(\d+)\s*[dD]$','tokens','once');
                    if ~isempty(tok)
                        n = str2double(tok{1});
                        dur = days(n);
                        return
                    end
                    % try sail through to parse as numeric seconds
                    num = str2double(s);
                    if ~isnan(num)
                        dur = seconds(num);
                        return
                    end
                    error('parse_timedelta:Format','Timedelta format not valid: %s', s);
                end
            end
            error('parse_timedelta:Type','timedelta or time period string required');
        end
    end
end

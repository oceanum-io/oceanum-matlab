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
            % query_ - a single struct describing the object
            %
            % Output arguments:
            % obj      - initialized Query object
            arguments
                query_
            end

            if isfield(query_,"datasource")
                obj.datasource = query_.datasource;
            else
                error("A datasource must be provided")
            end
            
            if isfield(query_,"parameters")
                obj.parameters = query_.parameters;
            % else
            %     obj.parameters = {};
            end

            if isfield(query_, "description")
                obj.description = query_.description;
            % else
            %     obj.description = NaN;
            end

            if isfield(query_, "variables")
                obj.variables = query_.variables;
            % else
            %     obj.variables = NaN;
            end

            if isfield(query_, "timefilter")
                obj.timefilter = query_.timefilter;
            % else
            %     obj.timefilter = NaN;
            end
            
            if isfield(query_, "geofilter")
                obj.geofilter = query_.geofilter;
            % else
            %     obj.geofilter = NaN;
            end
            
            if isfield(query_, "levelfilter")
                obj.levelfilter = query_.levelfilter;
            % else
            %     obj.levelfilter = NaN;
            end
            
            if isfield(query_, "coordfilter")
                obj.coordfilter = query_.coordfilter;
            % else
            %     obj.coordfilter = NaN;
            end
            
            if isfield(query_, "crs")
                obj.crs = query_.crs;
            % else
            %     obj.crs = NaN;
            end
            
            if isfield(query_, "aggregate")
                obj.aggregate = query_.aggregate;
            % else
            %     obj.aggregate = NaN;
            end
            
            if isfield(query_, "functions")
                obj.functions = query_.functions;
            % else 
            %     obj.functions = [];
            end
            
            if isfield(query_, "limit")
                obj.limit = query_.limit;
            % else 
            %     obj.limit = NaN;
            end
            
            if isfield(query_, "id")
                obj.id = query_.id;
            % else
            %     obj.id = NaN;
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
            % Iterate over all public properties and copy
            for i = 1:length(props)
                if ~isempty(props{i})
                    propName = props{i};
                    propValue = obj.(propName);
                    s.(propName) = propValue;
                end
            end
        end
        
        function json = encodeQueryForDatamesh(q)
        % ENCODEQUERYFORDATAMESH Prepare a MATLAB struct/Query for jsonencode so that
        % fields encode exactly as datamesh expects:
        %   - "parameters" must be an object {} (not a JSON array)
        %   - scalar/optional fields that are empty should be encoded as null (JSON null)
        %   - "functions" should be an array (empty -> [])
        %
        % Usage:
        %   json = encodeQueryForDatamesh(q);
        %   % q can be:
        %   %  - a MATLAB struct with the fields (datasource, parameters, description, ...)
        %   %  - an oceanum.datamesh.Query object that implements toStruct()/toJSON()
        %
        % Example:
        %   q = struct('datasource','lmao'); 
        %   json = encodeQueryForDatamesh(q)
        %   % -> '{"datasource":"lmao","parameters":{},"description":null,...}'
        %
        % Notes:
        %   - jsonencode maps NaN -> null in JSON; we use NaN to force null.
        %   - jsonencode maps a 0x0 struct -> {} in JSON; we use struct() for parameters.
        %   - cell arrays become JSON arrays. To produce JSON null we use NaN, not [].
        %
        % See also jsonencode
        
        % Normalize input to plain struct
        if isobject(q) && ismethod(q,'toStruct')
            s = q.toStruct();
        elseif isstruct(q)
            s = q;
        else
            error('encodeQueryForDatamesh:BadInput', 'Input must be struct or object with toStruct()');
        end
        
        % Helper: null placeholder (jsonencode converts NaN -> null)
        null = NaN;
        
        % Build output struct with all fields present
        out = struct();
        
        % datasource (use empty string if missing)
        if isfield(s,'datasource') && ~isempty(s.datasource)
            out.datasource = char(s.datasource);
        else
            out.datasource = '';
        end
        
        % parameters must be an object {} (empty struct) not an array
        if isfield(s,'parameters') && isstruct(s.parameters) && ~isempty(fieldnames(s.parameters))
            out.parameters = s.parameters;
        else
            out.parameters = struct(); % encodes to {} in JSON
        end
        
        % For many optional fields we want JSON null if not present/empty.
        % Use NaN to represent null in the encoded JSON.
        if isfield(s,'description') && ~isempty(s.description)
            out.description = s.description;
        else
            out.description = null;
        end
        
        % variables -> if present and nonempty keep as cell array, otherwise null
        if isfield(s,'variables') && ~isempty(s.variables)
            out.variables = s.variables;
        else
            out.variables = null;
        end
        
        % timefilter -> if present keep as-is (struct), otherwise null
        if isfield(s,'timefilter') && ~isempty(s.timefilter)
            out.timefilter = s.timefilter;
        else
            out.timefilter = null;
        end
        
        % geofilter
        if isfield(s,'geofilter') && ~isempty(s.geofilter)
            out.geofilter = s.geofilter;
        else
            out.geofilter = null;
        end
        
        % levelfilter
        if isfield(s,'levelfilter') && ~isempty(s.levelfilter)
            out.levelfilter = s.levelfilter;
        else
            out.levelfilter = null;
        end
        
        % coordfilter -> keep as null unless provided
        if isfield(s,'coordfilter') && ~isempty(s.coordfilter)
            out.coordfilter = s.coordfilter;
        else
            out.coordfilter = null;
        end
        
        % crs
        if isfield(s,'crs') && ~isempty(s.crs)
            out.crs = s.crs;
        else
            out.crs = null;
        end
        
        % aggregate (object) -> null if empty
        if isfield(s,'aggregate') && ~isempty(s.aggregate)
            out.aggregate = s.aggregate;
        else
            out.aggregate = null;
        end
        
        % functions -> should be an array (empty -> [])
        if isfield(s,'functions') && ~isempty(s.functions)
            out.functions = s.functions;
        else
            out.functions = {}; % encodes to [] in JSON
        end
        
        % limit -> numeric or null
        if isfield(s,'limit') && ~isempty(s.limit) && ~isnan(s.limit)
            out.limit = s.limit;
        else
            out.limit = null;
        end
        
        % id -> string or null
        if isfield(s,'id') && ~isempty(s.id)
            out.id = s.id;
        else
            out.id = null;
        end
        
        % Final JSON
        % jsonencode will convert:
        %   struct() -> {}    (good for parameters)
        %   NaN      -> null  (good for optional scalar/objects we want null)
        %   {} cell  -> []    (good for functions empty array)
        json = jsonencode(out);
        end

        function json = toJson(obj)
            %s = obj.toStruct();
            json = obj.encodeQueryForDatamesh;
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

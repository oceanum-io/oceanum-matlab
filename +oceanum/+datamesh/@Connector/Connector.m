classdef Connector < handle
    % CONNECTOR - Access Datamesh API and perform datamesh operations.
    %   obj = CONNECTOR(TOKEN) creates a connector using TOKEN (or the
    %   DATAMESH_TOKEN environment variable). Provides methods to list
    %   catalog, retrieve and load datasources, and run queries.
    %
    %   Methods:
    %       get_catalog    - Retrieve available datasources
    %       get_datasource - Fetch metadata for a datasource
    %       load_datasource- Download datasource contents
    %       query         - Run OceanQL queries against gateway
    %
    %   See also https://docs.oceanum.io/docs/index
    properties (Access=private)
        token % Datamesh Token
        service 
        gateway
        authHeaders
        verify
        proto
        host
        user
    end

    methods
        function obj = Connector(token, service, verify)
          % CONNECTOR constructs a connector for the DataMesh service
          %
          % Inputs:
          %     token   - API token (text scalar). Defaults to DATAMESH_TOKEN env var.
          %     service - Service base URL (text scalar). Defaults to production URL.
          %     verify  - Logical flag to verify TLS certificates (true/false).
          % Outputs:
          %     connector object
            arguments
                token {mustBeTextScalar} = getenv('DATAMESH_TOKEN')
                service {mustBeTextScalar} = 'https://datamesh.oceanum.io'
                verify logical = true
            end

            if isempty(token)
                error('oceanum:datamesh:Connector:missingToken', ...
                    'A valid token must be supplied or defined in environment variable DATAMESH_TOKEN');
            end

            obj.token = token;
            obj.service = getenv('DATAMESH_SERVICE');
            if isempty(obj.service)
                obj.service = service;
            end
            obj.verify = verify;

            % Parse service URL
            uri = matlab.net.URI(obj.service);
            obj.proto = uri.Scheme;
            obj.host = uri.Host;

            % Set up authentication headers
            if startsWith(token, 'Bearer ')
                obj.authHeaders = matlab.net.http.HeaderField('Authorization ', token);
            else
                obj.authHeaders = [matlab.net.http.HeaderField('Authorization', strcat('Token'," ", token)), ...                    
                    matlab.net.http.HeaderField('X-DATAMESH-TOKEN', token)];

            end

            % Set gateway
            obj.gateway = service;

            % Setup session 
            obj.user = obj.session(obj);
        end

        function result = get_host(obj)
         % GET_HOST gets the host part of the URL and returns it as a
         % string.
         %
         % Inputs:
         %      obj     - connector object
         % Outputs:
         %      result  - the host as a string
            arguments
                obj oceanum.datamesh.Connector = oceanum.datamesh.Connector()
            end
            
            result = obj.host;
        end

        function result = check_info(obj)
            % Currently not implemented yet.
            arguments
                obj oceanum.datamesh.Connector = oceanum.datamesh.Connector()
            end
            result = NaN;
        end

        function result = status(obj)
         % STATUS returns the status of the oceanum.datamesh.Connector()
         %
         % Inputs:
         %      obj     - connector object
         % Outputs:
         %      result  - true or false for whether the connector is
         %                connected to the servers.
            arguments
                obj oceanum.datamesh.Connector = oceanum.datamesh.Connector()
            end
            % Make request
            uri = matlab.net.URI(obj.gateway);
            method = matlab.net.http.RequestMethod.GET;
            request = matlab.net.http.RequestMessage(method, obj.authHeaders);
            response = send(request, uri);
            if response.StatusCode == matlab.net.http.StatusCode.OK
                fprintf('Datamesh connector created for %s\n', obj.host);
                result = true;
            else
                result = false;
            end
        end

        function catalog = get_catalog(obj, search, timefilter, geofilter, limit)
            % GETCATALOG - Retrieve datasource catalog with optional search and limit
            %
            % Inputs:
            %   obj   - connector object with proto/host/authHeaders
            %   search - optional search string (text scalar)
            %   timefilter - optional time filter search to restrict catalogue
            %   geofilter - optional geographic filter to restrict search
            %   limit - optional numeric limit on returned items
            % Outputs:
            %   catalog - oceanum.datamesh.Catalog object of search results
            arguments
                obj
                search {mustBeTextScalar} = ''
                timefilter string = [] 
                geofilter = struct.empty 
                limit int32 = NaN
            end

            % Build query parameters
            params = [];
            if ~isempty(search)
                params = [params, matlab.net.QueryParameter('search', search)];
            end
            if ~isnan(limit)
                params = [params, matlab.net.QueryParameter('limit', string(limit))];
            end
            % This only implements the 'range' timefilter [tstart tend]
            if ~isempty(timefilter)
                in_trange = obj.formatTimeFilterForInTrange(timefilter);
                if ~isempty(in_trange)
                    params = [params, matlab.net.QueryParameter('in_trange', in_trange)]; 
                end
            end
            
            % geofilter -> geom_intersects (accept WKT string or struct with .wkt)
            if ~isempty(geofilter)
                if ischar(geofilter) || isstring(geofilter)
                    params(end+1) = matlab.net.QueryParameter('geom_intersects', char(geofilter)); 
                elseif isstruct(geofilter) && isfield(geofilter,'wkt')
                    params(end+1) = matlab.net.QueryParameter('geom_intersects', char(geofilter.wkt));
                else
                    error('oceanum:datamesh:Connector:BadGeoFilter', ...
                        'geofilter must be a WKT string or a struct with field ''wkt''');
                end
            end


            % Make request
            uri = matlab.net.URI(strcat(obj.proto, '://', obj.host, '/datasource/'));
            if ~isempty(params)
                uri.Query = params;
            end
            method = matlab.net.http.RequestMethod.GET;
            request = matlab.net.http.RequestMessage(method, obj.authHeaders);
            response = send(request, uri);

            if response.StatusCode ~= matlab.net.http.StatusCode.OK
                error('oceanum:datamesh:Connector:catalogError', ...
                    'Failed to retrieve catalog: %s', char(response.StatusCode));
            end

            catalog = oceanum.datamesh.Catalog(response.Body.Data, obj);

        end

        % Helper function
        function s = formatTimeFilterForInTrange(~, timefilter)
            % FORMATTIMEFILTERFORINTRANGE Convert various timefilter types to "startZ,endZ"
            %
            % Accepts:
            %   - 1x2 datetime array
            %   - cellstr / string-array with 2 elements
            %   - struct with field 'times' (cell or array)
            %   - single-element (treated as start with open end / or vice-versa)
            %
            % Returns '' on unknown input or failure.
            % Written by Copilot.
        
            if isempty(timefilter)
                s = '';
                return;
            end
        
            % Default extremes (match Python example)
            defaultStart = datetime(1,1,1,'TimeZone','UTC');
            defaultEnd   = datetime(2500,1,1,'TimeZone','UTC');
        
            % Extract candidate start/end values into a cell {start, end}
            if isstruct(timefilter) && isfield(timefilter,'times')
                times = timefilter.times;
            else
                times = timefilter;
            end
        
            % Normalize into cell with up to 2 elements
            if isa(times,'datetime')
                times = num2cell(times);
            elseif isstring(times)
                times = cellstr(times);
            elseif ischar(times)
                times = {times};
            end
        
            if iscell(times)
                % ok
            else
                times = {times};
            end
        
            % Ensure two elements
            if numel(times) == 0
                times = {[],[]};
            elseif numel(times) == 1
                times{2} = [];
            else
                times = times(1:2);
            end
        
            startVal = times{1};
            endVal   = times{2};
        
            % Parse/normalize start
            try
                if isempty(startVal)
                    dtStart = defaultStart;
                elseif isa(startVal,'datetime')
                    dtStart = startVal;
                    if isempty(dtStart.TimeZone), dtStart.TimeZone = 'UTC'; else dtStart.TimeZone = 'UTC'; end
                else
                    % Let datetime try to parse strings flexibly
                    dtStart = datetime(startVal,'TimeZone','UTC');
                    if isempty(dtStart.TimeZone), dtStart.TimeZone = 'UTC'; end
                end
            catch
                dtStart = defaultStart;
            end
        
            % Parse/normalize end
            try
                if isempty(endVal)
                    dtEnd = defaultEnd;
                elseif isa(endVal,'datetime')
                    dtEnd = endVal;
                    if isempty(dtEnd.TimeZone), dtEnd.TimeZone = 'UTC'; else dtEnd.TimeZone = 'UTC'; end
                else
                    dtEnd = datetime(endVal,'TimeZone','UTC');
                    if isempty(dtEnd.TimeZone), dtEnd.TimeZone = 'UTC'; end
                end
            catch
                dtEnd = defaultEnd;
            end
        
            % If start > end, swap or error (we swap here)
            if dtStart > dtEnd
                tmp = dtStart; dtStart = dtEnd; dtEnd = tmp;
            end
        
            % Format as "YYYY-MM-DDTHH:MM:SSZ" using datestr for broad compatibility
            startStr = [datestr(dtStart, 'yyyy-mm-ddTHH:MM:SS') 'Z'];
            endStr   = [datestr(dtEnd,   'yyyy-mm-ddTHH:MM:SS') 'Z'];
        
            s = sprintf('%s,%s', startStr, endStr);
        end

        function datasource = get_datasource(obj, datasourceId)
          % GETDATASOURCE retrieves a datasource by its identifier
          %
          % Inputs:
          %     obj          - Connector instance providing datasource access
          %     datasourceId - text scalar identifier of the datasource
          %
          % Outputs:
          %     datasource   - the retrieved datasource object or struct
            arguments
                obj
                datasourceId {mustBeTextScalar}
            end

            uri = matlab.net.URI(strcat(obj.proto, '://', obj.host, '/datasource/', datasourceId));
            request = matlab.net.http.RequestMessage('GET', obj.authHeaders);
            response = send(request, uri);

            if response.StatusCode == matlab.net.http.StatusCode.NotFound
                error('oceanum:datamesh:Connector:notFound', ...
                    'Datasource %s not found', datasourceId);
            elseif response.StatusCode == matlab.net.http.StatusCode.Unauthorized
                error('oceanum:datamesh:Connector:unauthorized', ...
                    'Not authorized to access datasource %s', datasourceId);
            elseif response.StatusCode ~= matlab.net.http.StatusCode.OK
                error('oceanum:datamesh:Connector:requestError', ...
                    'Request failed with status %s', char(response.StatusCode));
            end

            data = response.Body.Data;
            props = data.properties;
            props.id = datasourceId;
            props.geom = data.geometry;
            props.bbox = data.bbox;

            datasource = oceanum.datamesh.Datasource(props);
        end

        function data = load_datasource(obj, datasourceId, size_limit, row_limit)
            % LOADDATASOURCE loads data for a given datasource identifier
            % IMPORTANT, It is not possible to load large datasources
            % into MATLAB due to size constraints
            %
            % Input arguments:
            %   obj                 - object instance providing datasource access
            %   datasourceId        - text scalar identifier of the datasource
            %   query_size_limit    - Optional parameter size limit of query
            %   row_limit           - Optional parameter row limit of query
            %
            % Output arguments:
            %   data                - loaded datasource content
            arguments
                obj
                datasourceId {mustBeTextScalar}
                size_limit int64 = 1000000000; % 1 GB
                row_limit int64 = 2000000; 
            end

            % For MATLAB implementation, we'll fetch the data directly
            % since MATLAB doesn't have the same async/dask capabilities

            % Get stage query to check if query is within size limits
            query_input = struct("datasource",datasourceId);
            stage_results = obj.stage_request(obj,query_input);

            % if datasource is too big for memory
            if stage_results.size > size_limit
                error('oceanum:datamesh:Connector:LoadDatasourceError', ...
                      'Load failed due to datasource size being %i which is gretaer than the 1 GB limit', stage_results.size)
            end

            % if datasource has too many rows to load in.
            if stage_results.dlen > row_limit
                warning('oceanum:datamesh:Connector:LoadDatasourceWarning', ...
                      'Datasource limited to 2,000,000 rows, not all data may be returned. Use a more specific query.')
            end

            uri = matlab.net.URI(strcat(obj.gateway, '/data/', datasourceId));
            headers = [obj.authHeaders matlab.net.http.HeaderField('Accept', 'application/json')];
            request = matlab.net.http.RequestMessage('GET', headers);
            response = send(request, uri);

            if response.StatusCode ~= matlab.net.http.StatusCode.OK
                error('oceanum:datamesh:Connector:loadError', ...
                    'Failed to load datasource %s: %s', datasourceId, char(response.StatusCode));
            end

            % Save response to temporary file and read with readtable
            % TODO: Fix saving
            tempFile = [tempname, '.json'];
            try
                fid = fopen(tempFile, 'wb');
                fwrite(fid, response.Body.Data);
                fclose(fid);

                % Try to read as parquet, fallback to CSV if needed
                try
                    data = readtable(tempFile, 'FileType');
                catch
                    % If parquet reading fails, the data might be in a different format
                    warning('oceanum:datamesh:Connector:formatWarning', ...
                        'Could not read as parquet, data format may not be fully supported in MATLAB');
                    data = [];
                end
            catch ME
                if exist(tempFile, 'file')
                    delete(tempFile);
                end
                rethrow(ME);
            end

            if exist(tempFile, 'file')
                delete(tempFile);
            end
        end

        function result = query(obj, query_input, query_size_limit, row_limit)
            % QUERY builds and execute a data query on the object datasource
            %
            % Input arguments:
            %   obj                 - connector object
            %   query_input         - structure with query inputs
            %   query_size_limit    - Optional parameter size limit of query
            %   row_limit           - Optional parameter row limit of query
            %
            % Output:
            %   result              - either a MATLAB table (if parquet could be read) or a
            %                         filepath to the downloaded payload (parquet or netCDF)
            arguments
                obj
                query_input struct
                query_size_limit int64 = 1000000000; % 1 GB
                row_limit int64 = 2000000;
            end

            
            if isfield(query_input, 'datasource')
                if length(char(query_input.datasource)) < 3
                    error('oceanum:datamesh:Connector:InvalidInput', ...
                        'Datasource ID must be 3 or more characters')
                end
            end
                

            % Get stage query to check if query is within size limits
            stage_results = obj.stage_request(obj,query_input);
            if isempty(stage_results)
                error('oceanum:datamesh:Connector:EmptyDatasource', ...
                      'No data found in datasource')
            end


            if stage_results.size > query_size_limit
                error('oceanum:datamesh:Connector:queryError', ...
                      'Query failed due to query size being %i which is greater than the 1 GB limit', stage_results.size)
            end
            if stage_results.dlen > row_limit
                warning('oceanum:datamesh:Connector:queryWarning', ...
                      'Query limited to 2000000 rows, not all data may be returned. Use a more specific query.')
            end
            
            % build URI and messagebody for query request
            queryStructure = matlab.net.http.MessageBody(query_input);
            session_data = obj.session(obj);
            uri = matlab.net.URI(strcat(obj.service, '/oceanql/'));
            
            % build headers (ensure obj.authHeaders is HeaderField array)
            headers =  [session_data.addHeader(obj.authHeaders), ...
                        matlab.net.http.field.ContentTypeField('application/json'), ...
                        matlab.net.http.HeaderField('accept', 'application/json')];
            
            % create RequestMessage with MessageBody wrapper for JSON
            request = matlab.net.http.RequestMessage( ...
                        'POST', ...
                        headers, ...
                        queryStructure);
           
            % send request
            query_response = send(request,uri);
            
            % Return results
            result = query_response.Body.Data;
            
        end
    end
    methods (Static)
        function user_session = session(obj,duration)
          % SESSION creates or retrieve a user session for given duration
          %
          % Inputs:
          %     obj             - session manager object
          %     duration        - requested session duration in seconds (int32), NaN for default
          %
          % Outputs:
          %     user_session    - handle or struct describing the created/retrieved session
            arguments
                obj
                duration int32 = NaN
            end
            
            % Get session id
            headers = [obj.authHeaders, matlab.net.http.HeaderField('Cache-Control', "no-store")];
            params = struct("duration",NaN,"allow_multiwrite", false);
            if ~isnan(duration)
                params.duration = duration;
            end
            uri = matlab.net.URI(strcat(obj.service, '/session/'));
            request = matlab.net.http.RequestMessage('GET', headers);
            response = send(request,uri);
            if response.StatusCode == matlab.net.http.StatusCode.NotFound
                error('oceanum:datamesh:Connector:notFound', ...
                    'Datasource %s not found', datasourceId);
            elseif response.StatusCode == matlab.net.http.StatusCode.Unauthorized
                error('oceanum:datamesh:Connector:unauthorized', ...
                    'Not authorized to access datasource %s', datasourceId);
            elseif response.StatusCode ~= matlab.net.http.StatusCode.OK
                error('oceanum:datamesh:Connector:requestError', ...
                    'Request failed with status %s', char(response.StatusCode));
            end
            data = response.Body.Data;

            user_session = oceanum.datamesh.Session(data,obj);
        end

        function stage_results = stage_request(obj,query_input)
            % STAGE_REQUEST posts the stage request from the OCEANQL server
            % and returns the body of the data.
            %
            % Inputs:
            %   obj             - Datamesh connector 
            %   query_input     - Query inputs as a MATLAB Structure.
            %
            % Outputs:
            %   stage_results   - A structure with the results of the
            %                     staged datasource.
            arguments
                obj
                query_input struct
            end

            % build URI and messagebody for stage request
            queryStructure = matlab.net.http.MessageBody(query_input);
            session_data = obj.session(obj);
            uri = matlab.net.URI(strcat(obj.service, '/oceanql/stage/'));
            
            % build headers
            headers = [session_data.addHeader(obj.authHeaders), ...
                        matlab.net.http.field.ContentTypeField('application/json'), ...
                        matlab.net.http.HeaderField('accept', 'application/json')];

            % create RequestMessage with MessageBody wrapper for JSON
                request = matlab.net.http.RequestMessage( ...
                        'POST', ...
                        headers, ...
                        queryStructure);
           
            % send request
            stage_response = send(request,uri);
        
            % handle responses (204 = no content)
            if stage_response.StatusCode == matlab.net.http.StatusCode.NoContent
                % no data
                stage_results = [];
                return;
            end

            if stage_response.StatusCode ~= matlab.net.http.StatusCode.OK
                error('oceanum:datamesh:Connector:NotFound', ...
                      'Query failed with status %s', char(stage_response.StatusCode));
            end

            % successful: response body available
            stage_results = oceanum.datamesh.Stage(stage_response.Body.Data);
        end
    end
end


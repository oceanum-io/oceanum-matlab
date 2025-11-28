classdef Connector < handle
    % CONNECTOR - Access Datamesh API and perform datamesh operations.
    %   obj = CONNECTOR(TOKEN) creates a connector using TOKEN (or the
    %   DATAMESH_TOKEN environment variable). Provides methods to list
    %   catalog, retrieve and load datasources, and run queries.
    %
    %   Methods:
    %       getCatalog    - Retrieve available datasources
    %       getDatasource - Fetch metadata for a datasource
    %       loadDatasource- Download datasource contents
    %       query         - Run OceanQL queries against gateway
    %
    %   See also matlab.net.URI, matlab.net.http.RequestMessage
    properties (Access=private)
        token % Datamesh Token
        service 
        gateway
        authHeaders
        verify
        proto
        host
    end

    methods
        function obj = Connector(token, service, verify)
          % CONNECTOR - Construct a Connector for the DataMesh service
          %
          % Input arguments:
          % token   - API token (text scalar). Defaults to DATAMESH_TOKEN env var.
          % service - Service base URL (text scalar). Defaults to production URL.
          % verify  - Logical flag to verify TLS certificates (true/false).
            arguments
                token {mustBeTextScalar} = getenv('DATAMESH_TOKEN')
                service {mustBeTextScalar} = 'https://datamesh.oceanum.io'
                verify logical = true
            end

            %%% implement into code later 
            user = NaN;


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
                obj.authHeaders = matlab.net.http.HeaderField('Authorization', token);
            else
                obj.authHeaders = [matlab.net.http.HeaderField('Authorization', strcat('Token ', token)), ...                    
                    matlab.net.http.HeaderField('X-DATAMESH-TOKEN', token)];

            end

            % Set gateway
            obj.gateway = strcat(obj.service, '/gateway/');

            fprintf('Datamesh connector created for %s\n', obj.host);
        end

        function catalog = get_catalog(obj, search, timefilter, geofilter, limit)
          % GETCATALOG - Retrieve datasource catalog with optional search and limit
          %
          % Input arguments:
          % obj   - connector object with proto/host/authHeaders
          % search - optional search string (text scalar)
          % timefilter - optional time filter search to restrict catalogue
          % geofilter - optional geographic filter to restrict search
          % limit - optional numeric limit on returned items
            arguments
                obj
                search {mustBeTextScalar} = ''
                timefilter string = [] 
                geofilter = [] 
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
            % timefilter -> in_trange
            if ~isempty(timefilter)
                in_trange = obj.formatTimeFilterForInTrange(timefilter);
                if ~isempty(in_trange)
                    params = [params, matlab.net.QueryParameter('in_trange', in_trange)]; 
                end
            end
            
            % Copilot generated code... TODO: Fix so it works properly
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
          % GETDATASOURCE - Retrieve a datasource by its identifier
          %
          % Input arguments:
          % obj          - Connector instance providing datasource access
          % datasourceId - text scalar identifier of the datasource
          %
          % Output arguments:
          % datasource   - the retrieved datasource object or struct
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

        function data = loadDatasource(obj, datasourceId, useDask)
            % LOADDATASOURCE - Load data for a given datasource identifier
            %
            % !!! IMPORTANT It is not possible to load large datasources
            % into matlab due to size !!!
            % Input arguments:
            % obj          - object instance providing datasource access
            % datasourceId - text scalar identifier of the datasource
            % useDask      - logical flag (ignored in MATLAB; placeholder)
            %
            % Output arguments:
            % data         - loaded datasource content
            arguments
                obj
                datasourceId {mustBeTextScalar}
                useDask logical = false % Need to see if this works in MATLAB...
            end

            % For MATLAB implementation, we'll fetch the data directly
            % since MATLAB doesn't have the same async/dask capabilities
            uri = matlab.net.URI([obj.gateway '/data/' datasourceId]);
            headers = [obj.authHeaders matlab.net.http.HeaderField('Accept', 'application/parquet')];
            request = matlab.net.http.RequestMessage('GET', headers);
            response = send(request, uri);

            if response.StatusCode ~= matlab.net.http.StatusCode.OK
                error('oceanum:datamesh:Connector:loadError', ...
                    'Failed to load datasource %s: %s', datasourceId, char(response.StatusCode));
            end

            % Save response to temporary file and read with readtable
            tempFile = [tempname, '.parquet'];
            try
                fid = fopen(tempFile, 'wb');
                fwrite(fid, response.Body.Data);
                fclose(fid);

                % Try to read as parquet, fallback to CSV if needed
                try
                    data = readtable(tempFile, 'FileType', 'parquet');
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

        function result = query(obj, datasource, variables, timefilter, geofilter, limit)
          % QUERY - Build and execute a data query on the object datasource
          %
          % Input arguments:
          % obj        - object providing query execution methods
          % datasource - optional datasource name (text scalar)
          % variables  - optional list of variable names (cell)
          % timefilter - optional time filtering struct
          % geofilter  - optional geographic filtering struct
          % limit      - optional numeric result limit
            arguments
                obj
                datasource {mustBeTextScalar} = ''
                variables cell = {}
                timefilter struct = struct.empty
                geofilter struct = struct.empty
                limit int32 = []
            end
              % Build query struct
              q = struct();
              if ~isempty(datasource)
                  q.datasource = char(datasource);
              end
              if ~isempty(variables)
                  q.variables = variables;
              end
              if ~isempty(limit)
                  q.limit = limit;
              end
            
              % Normalize timefilter
              if ~isempty(timefilter)
                  % Accept:
                  %  - struct with field 'times' and optional 'type'
                  %  - 1x2 datetime array or cell/strings {'start','end'} -> treat as range
                  if isstruct(timefilter) && isfield(timefilter,'times')
                      q.timefilter = timefilter;
                  else
                      % try to coerce simple forms into a TimeFilter-like struct
                      timesCell = {};
                      if isa(timefilter,'datetime')
                          timesCell = num2cell(timefilter);
                      elseif iscell(timefilter)
                          timesCell = timefilter;
                      elseif isstring(timefilter)
                          timesCell = cellstr(timefilter);
                      elseif ischar(timefilter)
                          timesCell = {timefilter};
                      elseif isnumeric(timefilter) && numel(timefilter)==2
                          % treat numeric inputs as datenum-style
                          try
                              timesCell = { datetime(timefilter(1), 'ConvertFrom','datenum'), ...
                                            datetime(timefilter(2), 'ConvertFrom','datenum') };
                          catch
                              timesCell = {};
                          end
                      end
            
                      % ensure two elements for range (open-ended allowed via empty element)
                      if numel(timesCell) == 0
                          % ignore if not parsable
                      else
                          if numel(timesCell) == 1
                              timesCell{2} = [];
                          end
                          % convert datetimes to ISO strings
                          isoTimes = cell(1,2);
                          for ii = 1:2
                              t = timesCell{ii};
                              if isempty(t)
                                  isoTimes{ii} = [];
                              elseif isa(t,'datetime')
                                  % force UTC and format without fractional seconds
                                  if isempty(t.TimeZone)
                                      t.TimeZone = 'UTC';
                                  else
                                      t.TimeZone = 'UTC';
                                  end
                                  isoTimes{ii} = [datestr(t, 'yyyy-mm-ddTHH:MM:SS') 'Z'];
                              else
                                  % assume string; pass through
                                  isoTimes{ii} = char(t);
                              end
                          end
                          q.timefilter = struct('type','range','times',{isoTimes});
                      end
                  end
              end
            
              % Normalize geofilter
              if ~isempty(geofilter)
                  % Accept:
                  %  - char/string WKT (we wrap into a minimal struct)
                  %  - struct with fields 'type' and 'geom' (assumed already suitable)
                  if ischar(geofilter) || isstring(geofilter)
                      q.geofilter = struct('type','feature','geom',char(geofilter));
                  elseif isstruct(geofilter)
                      % pass through basic struct (assumed to match the API shape)
                      q.geofilter = geofilter;
                  else
                      error('oceanum:datamesh:Connector:BadGeoFilter', ...
                          'geofilter must be a WKT string or a struct compatible with the API');
                  end
              end
            
              % JSON encode
              jsonData = jsonencode(q);
            
              % Endpoint
              

            
              % Build headers: combine auth headers and content headers
              try
                  authFields = obj.authHeaders; % expected to be HeaderField array in class
              catch
                  authFields = matlab.net.http.HeaderField('Authorization', ['Token ' char(obj.token)]);
              end
              headers = [authFields, HeaderField('Content-Type', 'application/json'), HeaderField('Accept', 'application/parquet')];
        
              req = RequestMessage(RequestMethod.POST, headers, MessageBody(jsonData));
              uri = URI(endpoint);
              resp = req.send(uri);
        
              if resp.StatusCode ~= matlab.net.http.StatusCode.OK
                  error('oceanum:datamesh:Connector:queryError', 'Query failed with status %s', char(resp.StatusCode));
              end
        
              payload = resp.Body.Data;
      
            
              % If payload is a MATLAB struct/table (JSON-decoded), return it directly
              if isstruct(payload) || istable(payload)
                  result = payload;
                  return;
              end
            
              % Otherwise we expect binary (parquet/netcdf). Save to temp file and attempt to parse.
              tmpFile = [tempname, '.dat'];
              fid = fopen(tmpFile, 'wb');
              if fid == -1
                  error('oceanum:datamesh:Connector:tmpfile', 'Could not create temporary file for payload');
              end
              try
                  if isa(payload, 'uint8')
                      fwrite(fid, payload, 'uint8');
                  elseif ischar(payload) || isstring(payload)
                      fwrite(fid, char(payload), 'uint8');
                  elseif iscell(payload) && isa(payload{1}, 'uint8')
                      fwrite(fid, payload{1}, 'uint8');
                  else
                      % attempt to write generic numeric data
                      fwrite(fid, typecast(payload(:),'uint8'), 'uint8');
                  end
                  fclose(fid);
              catch ME
                  fclose(fid);
                  delete(tmpFile);
                  rethrow(ME);
              end
            
              % Try parse parquet (if supported), else return filepath
              try
                  tbl = readtable(tmpFile, 'FileType', 'parquet');
                  result = tbl;
                  delete(tmpFile);
                  return;
              catch
                  % not parsable as parquet in this MATLAB, return filepath
                  result = tmpFile;
                  return;
              end
            

            


            % 
            % % Build query structure
            % queryStruct = struct();
            % queryStruct.datasource = datasource;
            % 
            % if ~isempty(variables)
            %     queryStruct.variables = variables;
            % end
            % if ~isempty(timefilter)
            %     queryStruct.timefilter = timefilter;
            % end
            % if ~isempty(geofilter)
            %     queryStruct.geofilter = geofilter;
            % end
            % if ~isempty(limit)
            %     queryStruct.limit = limit;
            % end
            % 
            % % Convert to JSON and make request
            % 
            % 
            % jsonData = jsonencode(queryStruct);
            % % uri = matlab.net.URI(strcat(obj.proto, '://', obj.host, '/datasource/'));
            % uri = matlab.net.URI(strcat(obj.gateway, '/oceanql/'));
            % 
            % headers = [obj.authHeaders, ... 
            %           matlab.net.http.HeaderField('Content-Type', 'application/json'), ...
            %           matlab.net.http.HeaderField('Accept', 'application/parquet')];
            % 
            % body = matlab.net.http.MessageBody(jsonData);
            % method = matlab.net.http.RequestMethod.POST; % Work on this last cause its gonna be a pain...
            % request = matlab.net.http.RequestMessage(method, headers, body);
            % response = send(request, uri);
            % 
            % if response.StatusCode ~= matlab.net.http.StatusCode.OK
            %     error('oceanum:datamesh:Connector:queryError', ...
            %         'Query failed with status %s', char(response.StatusCode));
            % end
            % 
            % 
            % tempFile = [tempname '.parquet'];
            % try
            %     fid = fopen(tempFile, 'wb');
            %     fwrite(fid, response.Body.Data);
            %     fclose(fid);
            % 
            %     try
            %         result = readtable(tempFile, 'FileType', 'parquet');
            %     catch
            %         warning('oceanum:datamesh:Connector:formatWarning', ...
            %             'Could not read query result as parquet');
            %         result = [];
            %     end
            % catch ME
            %     if exist(tempFile, 'file')
            %         delete(tempFile);
            %     end
            %     rethrow(ME);
            % end
            % 
            % if exist(tempFile, 'file')
            %     delete(tempFile);
            % end
        end
    end
end



   
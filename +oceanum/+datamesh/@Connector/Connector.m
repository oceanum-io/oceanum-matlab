classdef Connector < handle
    properties (Access=private)
        token
        service
        gateway
        authHeaders
        verify
        proto
        host
    end
    
    methods
        function obj = Connector(token, varargin)
            arguments
                token {mustBeTextScalar} = getenv('DATAMESH_TOKEN')
                options.service {mustBeTextScalar} = 'https://datamesh.oceanum.io'
                options.verify logical = true
            end
            
            if isempty(token)
                error('oceanum:datamesh:Connector:missingToken', ...
                    'A valid token must be supplied or defined in environment variable DATAMESH_TOKEN');
            end
            
            obj.token = token;
            obj.service = getenv('DATAMESH_SERVICE');
            if isempty(obj.service)
                obj.service = options.service;
            end
            obj.verify = options.verify;
            
            % Parse service URL
            uri = matlab.net.URI(obj.service);
            obj.proto = uri.Scheme;
            obj.host = uri.Host;
            
            % Set up authentication headers
            if startsWith(token, 'Bearer ')
                obj.authHeaders = matlab.net.http.HeaderField('Authorization', token);
            else
                obj.authHeaders = [
                    matlab.net.http.HeaderField('Authorization', ['Token ' token])
                    matlab.net.http.HeaderField('X-DATAMESH-TOKEN', token)
                ];
            end
            
            % Set gateway
            obj.gateway = [obj.service '/gateway/'];
            
            fprintf('Datamesh connector created for %s\n', obj.host);
        end
        
        function catalog = getCatalog(obj, varargin)
            arguments
                obj
                options.search {mustBeTextScalar} = ''
                options.limit double = []
            end
            
            % Build query parameters
            params = [];
            if ~isempty(options.search)
                params = [params matlab.net.QueryParameter('search', options.search)];
            end
            if ~isempty(options.limit)
                params = [params matlab.net.QueryParameter('limit', string(options.limit))];
            end
            
            % Make request
            uri = matlab.net.URI([obj.proto '://' obj.host '/datasource/']);
            if ~isempty(params)
                uri.Query = params;
            end
            
            request = matlab.net.http.RequestMessage('GET', obj.authHeaders);
            response = send(request, uri);
            
            if response.StatusCode ~= matlab.net.http.StatusCode.OK
                error('oceanum:datamesh:Connector:catalogError', ...
                    'Failed to retrieve catalog: %s', char(response.StatusCode));
            end
            
            catalog = oceanum.datamesh.Catalog(response.Body.Data, obj);
        end
        
        function datasource = getDatasource(obj, datasourceId)
            arguments
                obj
                datasourceId {mustBeTextScalar}
            end
            
            uri = matlab.net.URI([obj.proto '://' obj.host '/datasource/' datasourceId]);
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
            
            datasource = oceanum.datamesh.Datasource(props);
        end
        
        function data = loadDatasource(obj, datasourceId, varargin)
            arguments
                obj
                datasourceId {mustBeTextScalar}
                options.useDask logical = false
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
            tempFile = [tempname '.parquet'];
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
        
        function result = query(obj, varargin)
            arguments
                obj
                options.datasource {mustBeTextScalar} = ''
                options.variables cell = {}
                options.timefilter struct = struct.empty
                options.geofilter struct = struct.empty
                options.limit double = []
            end
            
            % Build query structure
            queryStruct = struct();
            queryStruct.datasource = options.datasource;
            
            if ~isempty(options.variables)
                queryStruct.variables = options.variables;
            end
            if ~isempty(options.timefilter)
                queryStruct.timefilter = options.timefilter;
            end
            if ~isempty(options.geofilter)
                queryStruct.geofilter = options.geofilter;
            end
            if ~isempty(options.limit)
                queryStruct.limit = options.limit;
            end
            
            % Convert to JSON and make request
            jsonData = jsonencode(queryStruct);
            uri = matlab.net.URI([obj.gateway '/oceanql/']);
            headers = [obj.authHeaders 
                      matlab.net.http.HeaderField('Content-Type', 'application/json')
                      matlab.net.http.HeaderField('Accept', 'application/parquet')];
            
            body = matlab.net.http.MessageBody(jsonData);
            request = matlab.net.http.RequestMessage('POST', headers, body);
            response = send(request, uri);
            
            if response.StatusCode ~= matlab.net.http.StatusCode.OK
                error('oceanum:datamesh:Connector:queryError', ...
                    'Query failed with status %s', char(response.StatusCode));
            end
            
            % Save and read response data similar to loadDatasource
            tempFile = [tempname '.parquet'];
            try
                fid = fopen(tempFile, 'wb');
                fwrite(fid, response.Body.Data);
                fclose(fid);
                
                try
                    result = readtable(tempFile, 'FileType', 'parquet');
                catch
                    warning('oceanum:datamesh:Connector:formatWarning', ...
                        'Could not read query result as parquet');
                    result = [];
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
    end
end

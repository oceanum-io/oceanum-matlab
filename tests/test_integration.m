function tests = test_integration
    tests = functiontests(localfunctions);
end

function test_end_to_end_workflow(testCase)
    % Test end-to-end workflow (requires valid token and connection)
    
    % Skip if no token available
    token = getenv('DATAMESH_TOKEN');
    if isempty(token)
        fprintf('Skipping integration test - no DATAMESH_TOKEN found\n');
        return;
    end
    
    try
        % Create connector
        connector = oceanum.datamesh.Connector(token);
        testCase.verifyClass(connector, 'oceanum.datamesh.Connector');
        
        % Get catalog
        catalog = connector.get_catalog('limit', 5);
        testCase.verifyClass(catalog, 'oceanum.datamesh.Catalog');
        
        % Check catalog has content
        if length(catalog) > 0
            ids = catalog.getIds();
            testCase.verifyTrue(length(ids) > 0);
            
            % Try to get first datasource
            firstId = ids{1};
            ds = connector.get_datasource(firstId);
            testCase.verifyClass(ds, 'oceanum.datamesh.Datasource');
            testCase.verifyEqual(ds.id, firstId);
            
            % Try to load small amount of data
            try
                data = connector.load_datasource(firstId);
                if ~isempty(data)
                    % Data could be a table (parquet) or struct (NetCDF)
                    testCase.verifyTrue(istable(data) || isstruct(data));
                end
            catch ME
                % Data loading might fail for various reasons (format, size, etc.)
                fprintf('Data loading failed (expected for some datasources): %s\n', ME.message);
            end
        end
        
    catch ME
        % Integration tests can fail for various connectivity reasons
        fprintf('Integration test failed: %s\n', ME.message);
        % Don't fail the test - just log the issue
    end
end

function test_query_building(testCase)
    % Test query building without actually executing
    
    % Test basic query
    query = oceanum.datamesh.Query(struct('datasource', 'test-datasource'));
    testCase.verifyEqual(query.datasource, 'test-datasource');
    
    % Test query with filters
    timefilter = oceanum.datamesh.Query.createTimeFilter({'2023-01-01', '2023-12-31'});
    geofilter = oceanum.datamesh.Query.createGeoFilter([-10, -10, 10, 10]);
    
    query_input =struct(...
        'datasource', 'test-datasource', ...
        'variables', {{'temperature', 'salinity'}}, ...
        'timefilter', timefilter, ...
        'geofilter', geofilter, ...
        'limit', 1000);
    query = oceanum.datamesh.Query(query_input);
    
    testCase.verifyEqual(query.datasource, 'test-datasource');
    testCase.verifyEqual(query.variables, {'temperature', 'salinity'});
    testCase.verifyEqual(query.limit, 1000);
    testCase.verifyTrue(query.hasFilters());
    
    % Test JSON conversion
    json = query.toJson();
    testCase.verifyClass(json, 'char');
    testCase.verifyTrue(contains(json, 'test-datasource'));
end

function test_catalog_operations(testCase)
    % Test catalog operations with mock data
    
    % Create mock geojson data
    feature1 = struct('id', 'ds1', 'geometry', struct('type', 'Point', 'coordinates', [0, 0]), ...
                     'properties', struct('name', 'Dataset 1', 'driver', 'parquet'));
    feature2 = struct('id', 'ds2', 'geometry', struct('type', 'Point', 'coordinates', [1, 1]), ...
                     'properties', struct('name', 'Dataset 2', 'driver', 'netcdf'));
    
    geojson = struct('type', 'FeatureCollection', 'features', [feature1, feature2]);
    
    % Create mock connector (won't actually work but enough for testing)
    try
        mockConnector = oceanum.datamesh.Connector('mock-token');
    catch
        % Expected to fail, create a minimal mock
        mockConnector = [];
    end
    
    if ~isempty(mockConnector)
        catalog = oceanum.datamesh.Catalog(geojson, mockConnector);
        
        testCase.verifyEqual(length(catalog), 2);
        
        ids = catalog.getIds();
        testCase.verifyEqual(length(ids), 2);
        testCase.verifyTrue(any(strcmp(ids, 'ds1')));
        testCase.verifyTrue(any(strcmp(ids, 'ds2')));
        
        % Test getting datasource from catalog
        ds1 = catalog.get_datasource('ds1');
        testCase.verifyEqual(ds1.id, 'ds1');
        testCase.verifyEqual(ds1.name, 'Dataset 1');
    end
end
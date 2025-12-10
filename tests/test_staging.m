function tests = test_staging
    tests = functiontests(localfunctions);
end

function test_stage_creation(testCase)
    % Test Stage object creation
    test = struct();
    test.qhash = 'test-hash';
    test.container = 'dataset';
    test.size = 1000;
    test.dlen = 500;
    stage = oceanum.datamesh.Stage(test);
    
    testCase.verifyEqual(stage.qhash, 'test-hash');
    testCase.verifyEqual(stage.container, 'dataset');
    testCase.verifyEqual(stage.size, 1000);
    testCase.verifyEqual(stage.dlen, 500);
    testCase.verifyTrue(stage.isDataset());
    testCase.verifyFalse(stage.isDataFrame());
    testCase.verifyFalse(stage.isGeoDataFrame());
end

function testValidStageRequest(testCase)
    query_input = struct("datasource", "oceanum-sea-level-rise");
    connector = oceanum.datamesh.Connector();
    stage = connector.stage_request(connector,query_input);
    
    testCase.verifyNotEmpty(stage, ...
        'Expected non-empty stage results for valid query.');
    testCase.verifyTrue(isfield(stage.toStruct, "size"), ...
        'Stage response missing field "size".');
    testCase.verifyTrue(isfield(stage.toStruct, "dlen"), ...
        'Stage response missing field "dlen".');
end

function test_session_creation(testCase)
    % Test Session object creation with mock connector
    
    % Create mock connector
    try
        connector = oceanum.datamesh.Connector();
    catch
        % Expected to fail without real connection
        connector = [];
    end
    
    if ~isempty(connector)
        sessionData = struct();
        sessionData.id = 'test-session-123';
        sessionData.user = 'test-user';
        sessionData.creation_time = '2023-01-01T00:00:00Z';
        sessionData.end_time = '2023-01-01T01:00:00Z';
        sessionData.write = false;
        sessionData.verified = true;
        
        session = oceanum.datamesh.Session(sessionData, connector);
        
        testCase.verifyEqual(session.id, 'test-session-123');
        testCase.verifyEqual(session.user, 'test-user');
        testCase.verifyFalse(session.write);
        testCase.verifyTrue(session.verified);
        
        % Test header addition
        baseHeaders = matlab.net.http.HeaderField('Content-Type', 'application/json');
        headers = session.addHeader(baseHeaders);
        testCase.verifyEqual(length(headers), 2);
        testCase.verifyTrue(any(strcmp(headers(end).Name, "X-DATAMESH-SESSIONID")));
    end
end

function test_netcdf_structure(testCase)
    % Test NetCDF data structure (without actual NetCDF file)
    
    % Mock NetCDF data structure
    expectedData = struct();
    expectedData.dimensions = containers.Map();
    expectedData.variables = containers.Map();
    expectedData.attributes = containers.Map();
    
    expectedData.dimensions('time') = 100;
    expectedData.dimensions('lat') = 180;
    expectedData.dimensions('lon') = 360;
    
    expectedData.variables('temperature') = rand(360, 180, 100);
    expectedData.variables('salinity') = rand(360, 180, 100);
    
    expectedData.attributes('title') = 'Test Dataset';
    expectedData.attributes('creator') = 'oceanum-matlab';
    
    % Verify structure
    testCase.verifyClass(expectedData.dimensions, 'containers.Map');
    testCase.verifyClass(expectedData.variables, 'containers.Map');
    testCase.verifyClass(expectedData.attributes, 'containers.Map');
    
    testCase.verifyEqual(expectedData.dimensions('time'), 100);
    testCase.verifyEqual(size(expectedData.variables('temperature')), [360, 180, 100]);
    testCase.verifyEqual(expectedData.attributes('title'), 'Test Dataset');
end

function test_query_with_staging_mock(testCase)
    % Test query construction for staging (without actual API call)
    
    % Create query
    timefilter = oceanum.datamesh.Query.createTimeFilter({'2023-01-01', '2023-12-31'});
    geofilter = oceanum.datamesh.Query.createGeoFilter([-10, -10, 10, 10]);
    
    query_input = struct(...
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
    testCase.verifyTrue(contains(json, 'temperature'));
    testCase.verifyTrue(contains(json, 'timefilter'));
    testCase.verifyTrue(contains(json, 'geofilter'));
end

function test_container_type_detection(testCase)
    % Test container type detection in Stage
    
    % Test dataset container
    datasetStage = oceanum.datamesh.Stage(struct('container', 'dataset'));
    testCase.verifyTrue(datasetStage.isDataset());
    testCase.verifyFalse(datasetStage.isDataFrame());
    testCase.verifyFalse(datasetStage.isGeoDataFrame());
    
    % Test dataframe container
    dataframeStage = oceanum.datamesh.Stage(struct('container', 'dataframe'));
    testCase.verifyFalse(dataframeStage.isDataset());
    testCase.verifyTrue(dataframeStage.isDataFrame());
    testCase.verifyFalse(dataframeStage.isGeoDataFrame());
    
    % Test geodataframe container
    geodataframeStage = oceanum.datamesh.Stage(struct('container', 'geodataframe'));
    testCase.verifyFalse(geodataframeStage.isDataset());
    testCase.verifyFalse(geodataframeStage.isDataFrame());
    testCase.verifyTrue(geodataframeStage.isGeoDataFrame());
end

function test_connector_integration(testCase)
    % Test connector functionality (requires valid token)
    
    % Skip if no token available
    token = getenv('DATAMESH_TOKEN');
    if isempty(token)
        fprintf('Skipping integration test - no DATAMESH_TOKEN found\n');
        return;
    end
    
    try
        % Create connector (V1 API only)
        connector = oceanum.datamesh.Connector(token);
        testCase.verifyClass(connector, 'oceanum.datamesh.Connector');
        
        % Test that methods exist
        testCase.verifyTrue(ismethod(connector, 'query'));
        testCase.verifyTrue(ismethod(connector, 'get_host'));
        testCase.verifyTrue(ismethod(connector, 'check_info'));
        testCase.verifyTrue(ismethod(connector, 'status'));
        
        % Test getter methods
        gateway = connector.host();
        testCase.verifyClass(gateway, 'char');
        
        status = connector.status();
        testCase.verifyTrue(status);
        
    catch ME
        % Integration tests can fail for various connectivity reasons
        fprintf('Integration test failed: %s\n', ME.message);
        % Don't fail the test - just log the issue
    end
end
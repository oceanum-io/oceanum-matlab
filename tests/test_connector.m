function tests = test_connector
    tests = functiontests(localfunctions);
end

function test_connector_creation(testCase)
    % Test that connector can be created with a token
    try
        % This will fail without a real token, but should test the constructor
        connector = oceanum.datamesh.Connector();
        testCase.verifyClass(connector, 'oceanum.datamesh.Connector');
    catch ME
        % Expected to fail without valid token/connection
        testCase.verifyTrue(contains(ME.message, 'token') || contains(ME.message, 'connect'));
    end
end

function test_connector_missing_token(testCase)
    % Test that connector creation fails without token
    testCase.verifyError(@() oceanum.datamesh.Connector(''), ...
        'oceanum:datamesh:Connector:missingToken');
end

function test_query_creation(testCase)
    % Test Query object creation
    query_input = struct("datasource",'test',"limit",100);
    query = oceanum.datamesh.Query(query_input);
    
    testCase.verifyEqual(query.datasource, 'test');
    testCase.verifyEqual(query.limit, 100);
end

function test_query_from_struct(testCase)
    % Test Query creation from struct
    s = struct('datasource', 'test-ds', 'variables', {{'var1', 'var2'}});
    query = oceanum.datamesh.Query(s);
    
    testCase.verifyEqual(query.datasource, 'test-ds');
    testCase.verifyEqual(query.variables, {'var1', 'var2'});
end

function test_datasource_creation(testCase)
    % Test Datasource object creation
    props = struct('id', 'test-id', 'name', 'Test Datasource', 'driver', 'parquet');
    ds = oceanum.datamesh.Datasource(props);
    
    testCase.verifyEqual(ds.id, 'test-id');
    testCase.verifyEqual(ds.name, 'Test Datasource');
    testCase.verifyEqual(ds.driver, 'parquet');
end

function test_time_filter_helper(testCase)
    % Test time filter creation helper
    times = {'2023-01-01', '2023-12-31'};
    timefilter = oceanum.datamesh.Query.createTimeFilter(times);
    
    testCase.verifyEqual(timefilter.type, 'range');
    testCase.verifyEqual(timefilter.times, times);
    testCase.verifyEqual(timefilter.resolution, 'native');
end

function test_geo_filter_helper(testCase)
    % Test geo filter creation helper
    bbox = [-180, -90, 180, 90];
    geofilter = oceanum.datamesh.Query.createGeoFilter(bbox);
    
    testCase.verifyEqual(geofilter.type, 'bbox');
    testCase.verifyEqual(geofilter.geom, bbox);
    testCase.verifyEqual(geofilter.interp, 'linear');
end

function test_level_filter_helper(testCase)
    % Test level filter creation helper
    levels = [0, 100];
    levelfilter = oceanum.datamesh.Query.createLevelFilter(levels);
    
    testCase.verifyEqual(levelfilter.type, 'range');
    testCase.verifyEqual(levelfilter.levels, levels);
    testCase.verifyEqual(levelfilter.interp, 'linear');
end
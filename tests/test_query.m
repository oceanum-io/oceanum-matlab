function tests = test_query
    tests = functiontests(localfunctions);
end

function test_query_connection(testCase)
    % test if our connector is working first
    connector = oceanum.datamesh.Connector();
    testCase.verifyClass(connector, 'oceanum.datamesh.Connector');
end

function test_query_staging(testCase)
    connector = oceanum.datamesh.Connector();
    query_input = struct("datasource","oceanum-sea-level-rise");
    results = connector.stage_request(connector, query_input);
    names = fieldnames(results);
    testCase.verifyEqual(names{1}, 'query');
    testCase.verifyLessThanOrEqual(results.size,1000000000)
    testCase.verifyLessThanOrEqual(results.dlen, 2000000)
end

function test_query_dataRetrieval(testCase)
    % test if data can be retrieved successfully (assuming you have the
    % proper token set in your work environment.
    connector = oceanum.datamesh.Connector();
    query_input = struct("datasource","oceanum-sea-level-rise");
    data = connector.query(query_input);
    testCase.verifyNumElements(data, 1);
end

function test_query_invalidDatasource(testCase)
    connector = oceanum.datamesh.Connector();
    query_input = struct("datasource","invalid-datasource");
    testCase.verifyError(@() connector.query(query_input), 'oceanum:datamesh:Connector:NotFound'); % Test for error on invalid datasource
end

function test_query_emptyDatasource(testCase)
    connector = oceanum.datamesh.Connector();
    query_input = struct("datasource","12");
    testCase.verifyError(@() connector.query(query_input), 'oceanum:datamesh:Connector:InvalidInput'); % Test for error on empty datasource
end

function test_query_multipleDatasources(testCase)
    connector = oceanum.datamesh.Connector();
    query_inputs = [
        struct("datasource","oceanum-sea-level-rise"),
        struct("datasource","nrc-mcleods_bay_trib_at_batting_north")
    ];
    for i = 1:length(query_inputs)
        data = connector.query(query_inputs(i));
        testCase.verifyNumElements(data, i); % Verify each query returns data
    end
end
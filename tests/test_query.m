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
    testCase.verify(results, 'query');
end

function test_query_dataRetrieval(testCase)
    % test if data can be retrieved successfully (assuming you have the
    % proper token set in your work environment.
    connector = oceanum.datamesh.Connector();
    query_input = struct("datasource","oceanum-sea-level-rise");
    data = connector.query(query_input);
    testCase.verifyField(data, 'data_vars');
end
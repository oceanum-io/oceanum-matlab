function tests = test_query
    tests = functiontests(localfunctions);
end

function test_connection(testcase)
    % test if our connector is working first
    connector = oceanum.datamesh.Connector;
    testCase.verifyClass(connector, 'oceanum.datamesh.Connector');
end

function test_dataRetrieval(testcase)
    % test if data can be retrieved successfully
    data = connector.;
    testCase.verifyNotEmpty(data);
end
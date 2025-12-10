function results = run_tests()
    % Run all tests for the oceanum-matlab library
    clc
    fprintf('Running oceanum-matlab tests...\n\n');
    
    % Add the parent directory to path so we can access the +oceanum package
    addpath(fullfile(fileparts(mfilename('fullpath')), '..'));
    
    % Run unit tests
    fprintf('=== Unit Tests ===\n');
    try
        suite1 = testsuite('test_connector.m');
        results1 = run(suite1);
        fprintf('Basic unit tests completed: %d passed, %d failed\n', ...
            sum([results1.Passed]), sum([results1.Failed]));
    catch ME
        fprintf('Basic unit tests failed to run: %s\n', ME.message);
        results1 = [];
    end
    
    % Run staging tests
    try
        suite_staging = testsuite('test_staging.m');
        results_staging = run(suite_staging);
        fprintf('Staging tests completed: %d passed, %d failed\n\n', ...
            sum([results_staging.Passed]), sum([results_staging.Failed]));
    catch ME
        fprintf('Staging tests failed to run: %s\n\n', ME.message);
        results_staging = [];
    end
    
    % Run integration tests
    fprintf('=== Integration Tests ===\n');
    try
        suite2 = testsuite('test_integration.m');
        results2 = run(suite2);
        fprintf('Integration tests completed: %d passed, %d failed\n\n', ...
            sum([results2.Passed]), sum([results2.Failed]));
    catch ME
        fprintf('Integration tests failed to run: %s\n\n', ME.message);
        results2 = [];
    end

    % Run query tests 
    fprintf('=== Integration Tests ===\n');
    try
        suite3 = testsuite('test_query.m');
        results3 = run(suite3);
        fprintf('Query tests completed: %d passed, %d failed\n\n', ...
            sum([results3.Passed]), sum([results3.Failed]));
    catch ME
        fprintf('Query tests failed to run: %s\n\n', ME.message);
        results3 = [];
    end
    
    % Combine results
    results = [];
    if ~isempty(results1)
        results = [results results1];
    end
    if ~isempty(results_staging)
        results = [results results_staging];
    end
    if ~isempty(results2)
        results = [results results2];
    end
    if ~isempty(results3)
        results = [results results3];
    end
    
    if ~isempty(results)
        fprintf('=== Summary ===\n');
        fprintf('Total tests: %d\n', length(results));
        fprintf('Passed: %d\n', sum([results.Passed]));
        fprintf('Failed: %d\n', sum([results.Failed]));
        
        if sum([results.Failed]) > 0
            fprintf('\nFailed tests:\n');
            for i = 1:length(results)
                if results(i).Failed
                    fprintf('  - %s\n', results(i).Name);
                end
            end
        end
    else
        fprintf('No tests could be run.\n');
    end
    
    fprintf('\nNote: Integration tests require a valid DATAMESH_TOKEN environment variable.\n');
    fprintf('Set it with: setenv(''DATAMESH_TOKEN'', ''your-token-here'')\n');
end
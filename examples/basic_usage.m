%% Basic Usage Example for oceanum-matlab
% This script demonstrates basic usage of the oceanum-matlab library

%% Setup
% Add the library to your MATLAB path
addpath('../');  % Adjust path as needed

% Set your datamesh token (get this from your Oceanum account)
% Option 1: Set environment variable (recommended)
% setenv('DATAMESH_TOKEN', 'your-token-here');

% Option 2: Pass directly to constructor (less secure)
% token = 'your-token-here';

%% Create Connection
fprintf('=== Creating Datamesh Connection ===\n');

try
    % Create connector (will use DATAMESH_TOKEN environment variable)
    connector = oceanum.datamesh.Connector();
    fprintf('Connected successfully!\n\n');
catch ME
    fprintf('Connection failed: %s\n', ME.message);
    fprintf('Make sure you have set DATAMESH_TOKEN environment variable\n');
    return;
end

%% Browse Catalog
fprintf('=== Browsing Catalog ===\n');

try
    % Get catalog with a limit to avoid too much data
    catalog = connector.getCatalog('limit', 10);
    fprintf('Found %d datasources:\n', length(catalog));
    
    % Display catalog
    disp(catalog);
    
    % Get list of datasource IDs
    ids = catalog.getIds();
    if ~isempty(ids)
        fprintf('\nFirst few datasource IDs:\n');
        for i = 1:min(3, length(ids))
            fprintf('  %s\n', ids{i});
        end
    end
    fprintf('\n');
    
catch ME
    fprintf('Catalog browsing failed: %s\n\n', ME.message);
end

%% Get Individual Datasource
if exist('ids', 'var') && ~isempty(ids)
    fprintf('=== Getting Individual Datasource ===\n');
    
    try
        % Get first datasource
        firstId = ids{1};
        datasource = connector.getDatasource(firstId);
        
        fprintf('Datasource details:\n');
        disp(datasource);
        fprintf('\n');
        
    catch ME
        fprintf('Getting datasource failed: %s\n\n', ME.message);
    end
end

%% Load Data
if exist('firstId', 'var')
    fprintf('=== Loading Data ===\n');
    
    try
        % Load datasource data
        data = connector.loadDatasource(firstId);
        
        if ~isempty(data)
            fprintf('Loaded data successfully!\n');
            fprintf('Data type: %s\n', class(data));
            if istable(data)
                fprintf('Rows: %d, Columns: %d\n', height(data), width(data));
                fprintf('Column names: %s\n', strjoin(data.Properties.VariableNames, ', '));
                
                % Display first few rows
                if height(data) > 0
                    fprintf('\nFirst few rows:\n');
                    disp(head(data, min(3, height(data))));
                end
            end
        else
            fprintf('No data returned\n');
        end
        fprintf('\n');
        
    catch ME
        fprintf('Loading data failed: %s\n', ME.message);
        fprintf('This is common - not all datasources support direct loading\n\n');
    end
end

%% Make a Query
if exist('firstId', 'var')
    fprintf('=== Making a Query ===\n');
    
    try
        % Create a simple query with limit
        result = connector.query('datasource', firstId, 'limit', 100);
        
        if ~isempty(result)
            fprintf('Query executed successfully!\n');
            fprintf('Result type: %s\n', class(result));
            if istable(result)
                fprintf('Rows: %d, Columns: %d\n', height(result), width(result));
            end
        else
            fprintf('Query returned no data\n');
        end
        fprintf('\n');
        
    catch ME
        fprintf('Query failed: %s\n\n', ME.message);
    end
end

%% Advanced Query Building and Staging
fprintf('=== Advanced Query Building and Staging ===\n');

% Create time filter
timefilter = oceanum.datamesh.Query.createTimeFilter(...
    {'2023-01-01', '2023-12-31'}, 'type', 'range');

% Create geo filter (bounding box)
geofilter = oceanum.datamesh.Query.createGeoFilter(...
    [-10, -10, 10, 10], 'type', 'bbox');

% Create query object
query = oceanum.datamesh.Query(...
    'datasource', 'example-datasource', ...
    'variables', {{'temperature', 'salinity'}}, ...
    'timefilter', timefilter, ...
    'geofilter', geofilter, ...
    'limit', 1000);

fprintf('Created query:\n');
disp(query);

% Convert to JSON (useful for debugging)
json = query.toJson();
fprintf('Query as JSON:\n%s\n\n', json);

%% Test Enhanced Functionality
if exist('connector', 'var') && ~isempty(connector)
    fprintf('=== Enhanced Query Features ===\n');
    
    try
        % Test connector capabilities
        fprintf('Gateway URL: %s\n', connector.getGateway());
        
        % The query methods automatically use internal staging
        fprintf('Query methods include:\n');
        fprintf('- Automatic format detection (NetCDF for datasets, Parquet for tables)\n');
        fprintf('- Size warnings and limits for large queries\n');
        fprintf('- Automatic session management\n');
        fprintf('- Error handling for queries that are too large\n\n');
        
    catch ME
        fprintf('Enhanced functionality test failed: %s\n\n', ME.message);
    end
end

%% Summary
fprintf('=== Summary ===\n');
fprintf('This example demonstrated:\n');
fprintf('1. Creating a datamesh connection\n');
fprintf('2. Browsing the catalog\n');
fprintf('3. Getting individual datasources\n');
fprintf('4. Loading data\n');
fprintf('5. Making queries\n');
fprintf('6. Building advanced queries\n');
fprintf('7. Enhanced query functionality with automatic staging\n');
fprintf('8. NetCDF support for dataset containers\n');
fprintf('9. Query size limits and error handling\n\n');

fprintf('For more information, see the documentation at:\n');
fprintf('https://oceanum-python.readthedocs.io/\n');
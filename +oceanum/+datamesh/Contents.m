% OCEANUM DATAMESH - MATLAB library for Oceanum.io platform
%
% Classes:
%   Connector   - Main class for connecting to and querying the datamesh
%   Catalog     - Catalog browser for datasources
%   Datasource  - Individual datasource metadata
%   Query       - Query builder and container
%   Stage       - Internal query staging information
%   Session     - Automatic session management
%
% Example usage:
%   % Connect to datamesh
%   connector = oceanum.datamesh.Connector('your-token');
%   
%   % Get catalog
%   catalog = connector.get_catalog();
%   
%   % Load a full datasource
%   data = connector.load_datasource('datasource-id');
%   
%   % Make a query
%   query = struct('datasource', 'datasource-id', 'limit', 1000);
%   result = connector.query(query);
%
% For more information, see the documentation at:
% https://oceanum-python.readthedocs.io/

% Version 1.0.0
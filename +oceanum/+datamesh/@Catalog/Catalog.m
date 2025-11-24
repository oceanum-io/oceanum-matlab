classdef Catalog < handle
    %CATALOG - Minimal wrapper for a GeoJSON feature collection
    %   C = CATALOG(CONNECTOR) stores parsed geojson, feature ids, and a
    %   connector object used for IO or network operations.
    %
    %   Properties:
    %       geojson   - Parsed GeoJSON structure
    %       ids       - Cached list of feature identifiers
    %       connector - External connector for data access
    properties (Access=private)
        geojson
        ids
        connector
    end
    
    methods
        function obj = Catalog(geojsonData, connector)
            % CATALOG - Construct a Catalog from GeoJSON and a connector
            %
            % Input arguments:
            % geojsonData - struct containing GeoJSON FeatureCollection
            % connector   - oceanum.datamesh.Connector to access datasources
            arguments
                geojsonData struct
                connector oceanum.datamesh.Connector
            end
            
            obj.geojson = geojsonData;
            obj.connector = connector;
            
            % Extract datasource IDs
            if isfield(geojsonData, 'features') && ~isempty(geojsonData.features)
                % Preallocate cell array for feature ids
                obj.ids = cell(length(geojsonData.features), 1);
                for i = 1:length(geojsonData.features)
                    obj.ids{i} = geojsonData.features(i).id;
                end
            else
                obj.ids = {};
            end
        end
        
        function n = length(obj)
          % LENGTH - Return number of stored identifiers
          %
          % Input arguments:
          % obj - object containing field 'ids'
          %
          % Output arguments:
          % n   - number of elements in obj.ids
            n = length(obj.ids);
        end
        
        function str = char(obj)
          % CHAR - Create human-readable summary of a datamesh catalog
          %
          % Input arguments:
          % obj - datamesh catalog object containing ids and geojson
          %
          % Output arguments:
          % str - formatted string listing each datasource
            % Build a human-readable summary listing each datasource
            str = sprintf('Datamesh catalog with %d datasources:', length(obj.ids));
            for i = 1:length(obj.ids)
                feature = obj.geojson.features(i);
                % Prefer explicit feature name when available
                if isfield(feature.properties, 'name')
                    name = feature.properties.name;
                else
                    name = feature.id;
                end
                str = sprintf('%s\n %s [%s]', str, name, feature.id);
            end
        end
        
        function disp(obj)
          % DISP - Display object as character vector on a new line
          %
          % Input arguments:
          % obj - object implementing char conversion
            fprintf('%s\n', char(obj));
        end
        
        function datasource = get_datasource(obj, datasourceId)
          % GET_DATASOURCE - Retrieve a Datasource object by its ID from catalog
          %
          % Input arguments:
          % obj - catalog-like object containing ids and geojson.features
          % datasourceId - text scalar identifier of the datasource
          %
          % Output arguments:
          % datasource - instantiated oceanum.datamesh.Datasource for that id
            arguments
                obj
                datasourceId {mustBeTextScalar}
            end
            
            idx = find(strcmp(obj.ids, datasourceId), 1);
            if isempty(idx)
                error('oceanum:datamesh:Catalog:notFound', ...
                    'Datasource %s not found in catalog', datasourceId);
            end
            
            % Assemble properties expected by Datasource constructor
            feature = obj.geojson.features(idx);
            props = feature.properties;
            props.id = feature.id;
            props.geom = feature.geometry;
            
            datasource = oceanum.datamesh.Datasource(props);
        end
        
        function data = load(obj, datasourceId, useDask)
          % LOAD - Load a datasource from the catalog
          %
          % Input arguments:
          % obj - catalog object
          % datasourceId - identifier of the datasource (text scalar)
          % useDask - logical flag to request Dask-backed loading (optional)
            arguments
                obj
                datasourceId {mustBeTextScalar}
                useDask logical = false
            end
            
            % Verify the requested datasource exists in the catalog
            if ~any(strcmp(obj.ids, datasourceId))
                error('oceanum:datamesh:Catalog:notFound', ...
                    'Datasource %s not found in catalog', datasourceId);
            end
            
            % Delegate loading to the connector (optionally using Dask)
            data = obj.connector.loadDatasource(datasourceId, 'useDask', useDask);
        end
        
        function result = query(obj, datasource, variables, timefilter, geofilter, limit)
          % QUERY - Query a datasource with optional filters and limit
          %
          % Input arguments:
          % obj        - caller object
          % datasource - datasource name (text scalar), default ''
          % variables  - cell array of variable names to return, default {}
          % timefilter - struct with time filtering criteria, default empty
          % geofilter  - struct with geographic filtering criteria, default empty
          % limit      - numeric limit on number of results, default []
            arguments
                obj
                datasource {mustBeTextScalar} = ''
                variables cell = {}
                timefilter struct = struct.empty
                geofilter struct = struct.empty
                limit double = []
            end
            
            % Validate requested datasource exists in this catalog
            if ~any(strcmp(obj.ids, options.datasource))
                error('oceanum:datamesh:Catalog:notFound', ...
                    'Datasource %s not found in catalog', datasource);
            end
            
            result = obj.connector.query(datasource, variables, timefilter, geofilter, limit);
        end
        
        function idList = getIds(obj)
          % GETIDS - Return stored identifier list from the object
          %
          % Input arguments:
          % obj - object containing an 'ids' property
          %
          % Output arguments:
          % idList - copy of obj.ids
            idList = obj.ids;
        end
        
        function idList = keys(obj)
          % KEYS - Return stored identifier list from the object
          %
          % Input arguments:
          % obj    - object containing an 'ids' property
          %
          % Output arguments:
          % idList - cell/array of identifiers stored in obj.ids
            idList = obj.ids;
        end
    end
end
classdef Catalog < handle
    properties (Access=private)
        geojson
        ids
        connector
    end
    
    methods
        function obj = Catalog(geojsonData, connector)
            arguments
                geojsonData struct
                connector oceanum.datamesh.Connector
            end
            
            obj.geojson = geojsonData;
            obj.connector = connector;
            
            % Extract datasource IDs
            if isfield(geojsonData, 'features') && ~isempty(geojsonData.features)
                obj.ids = cell(length(geojsonData.features), 1);
                for i = 1:length(geojsonData.features)
                    obj.ids{i} = geojsonData.features(i).id;
                end
            else
                obj.ids = {};
            end
        end
        
        function n = length(obj)
            n = length(obj.ids);
        end
        
        function str = char(obj)
            str = sprintf('Datamesh catalog with %d datasources:', length(obj.ids));
            for i = 1:length(obj.ids)
                feature = obj.geojson.features(i);
                if isfield(feature.properties, 'name')
                    name = feature.properties.name;
                else
                    name = feature.id;
                end
                str = sprintf('%s\n %s [%s]', str, name, feature.id);
            end
        end
        
        function disp(obj)
            fprintf('%s\n', char(obj));
        end
        
        function datasource = getDatasource(obj, datasourceId)
            arguments
                obj
                datasourceId {mustBeTextScalar}
            end
            
            idx = find(strcmp(obj.ids, datasourceId), 1);
            if isempty(idx)
                error('oceanum:datamesh:Catalog:notFound', ...
                    'Datasource %s not found in catalog', datasourceId);
            end
            
            feature = obj.geojson.features(idx);
            props = feature.properties;
            props.id = feature.id;
            props.geom = feature.geometry;
            
            datasource = oceanum.datamesh.Datasource(props);
        end
        
        function data = load(obj, datasourceId, varargin)
            arguments
                obj
                datasourceId {mustBeTextScalar}
                options.useDask logical = false
            end
            
            if ~any(strcmp(obj.ids, datasourceId))
                error('oceanum:datamesh:Catalog:notFound', ...
                    'Datasource %s not found in catalog', datasourceId);
            end
            
            data = obj.connector.loadDatasource(datasourceId, 'useDask', options.useDask);
        end
        
        function result = query(obj, varargin)
            arguments
                obj
                options.datasource {mustBeTextScalar} = ''
                options.variables cell = {}
                options.timefilter struct = struct.empty
                options.geofilter struct = struct.empty
                options.limit double = []
            end
            
            if ~any(strcmp(obj.ids, options.datasource))
                error('oceanum:datamesh:Catalog:notFound', ...
                    'Datasource %s not found in catalog', options.datasource);
            end
            
            result = obj.connector.query(varargin{:});
        end
        
        function idList = getIds(obj)
            idList = obj.ids;
        end
        
        function idList = keys(obj)
            idList = obj.ids;
        end
    end
end
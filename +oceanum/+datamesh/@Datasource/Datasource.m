classdef Datasource < handle
    % Fields
    properties (Access = public)
        coordinates
        created
        dataschema
        description
        details
        driver
        driver_args
        expires
        geom
        id
        info
        labels
        modified
        name
        parameters
        parchive
        pforecast
        tags
        tend
        tstart
    end
    % Properties
    properties (Access = public)
        attributes
        bounds
        geometry
    end
    
    methods
        function obj = Datasource(props)
            arguments
                props struct
            end
            
            % Set properties from input struct
            if isfield(props, 'id')
                obj.id = props.id;
            end
            if isfield(props, 'name')
                obj.name = props.name;
            end
            if isfield(props, 'description')
                obj.description = props.description;
            end
            if isfield(props, 'geom')
                obj.geom = props.geom;
            end
            if isfield(props, 'driver')
                obj.driver = props.driver;
            end
            if isfield(props, 'driver_args')
                obj.driverArgs = props.driver_args;
            end
            if isfield(props, 'variables')
                obj.variables = props.variables;
            end
            if isfield(props, 'coordinates')
                obj.coordinates = props.coordinates;
            end
            if isfield(props, 'crs')
                obj.crs = props.crs;
            end
            if isfield(props, 'tags')
                obj.tags = props.tags;
            end
            if isfield(props, 'metadata')
                obj.metadata = props.metadata;
            end
            if isfield(props, 'created')
                obj.created = props.created;
            end
            if isfield(props, 'updated')
                obj.updated = props.updated;
            end
            if isfield(props, 'size')
                obj.size = props.size;
            end
            if isfield(props, 'dlen')
                obj.dlen = props.dlen;
            end
        end
        
        function str = char(obj)
            str = sprintf('Datasource: %s [%s]', obj.name, obj.id);
            if ~isempty(obj.description)
                str = sprintf('%s\nDescription: %s', str, obj.description);
            end
            if ~isempty(obj.variables)
                if iscell(obj.variables)
                    vars = strjoin(obj.variables, ', ');
                else
                    vars = jsonencode(obj.variables);
                end
                str = sprintf('%s\nVariables: %s', str, vars);
            end
            if ~isempty(obj.size)
                str = sprintf('%s\nSize: %d bytes', str, obj.size);
            end
        end
        
        function disp(obj)
            fprintf('%s\n', char(obj));
        end
        
        function s = toStruct(obj)
            % Convert datasource to struct representation
            s = struct();
            
            props = properties(obj);
            for i = 1:length(props)
                propName = props{i};
                propValue = obj.(propName);
                if ~isempty(propValue)
                    s.(propName) = propValue;
                end
            end
        end
        
        function json = toJson(obj)
            % Convert datasource to JSON string
            s = obj.toStruct();
            json = jsonencode(s);
        end
    end
end
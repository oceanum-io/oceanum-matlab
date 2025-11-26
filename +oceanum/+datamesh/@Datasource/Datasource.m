classdef Datasource < handle
    % DATASOURCE - Representation of a data source with metadata and schema
    %   DS = DATASOURCE() encapsulates metadata, spatial-temporal bounds,
    %   schema and driver configuration for accessing dataset contents.
    %
    %   Data Fields:
    %       coordinates, geom, geometry - spatial coordinate representations
    %       tstart, tend, created, modified - temporal and provenance info
    %       dataschema, attributes, variables - schema and variable info
    %       driver, driver_args - backend driver configuration
    %   Datasource Properties
    %       attributes - Datasource global attributes. Note that these are None (undefined) for a summary dataset.
    %       bounds - Bounding box of datasource geographical extent
    %       geometry - geometry of datasource
    %       variables - Datasource variables (or properties). Note that these are None (undefined) for a summary dataset.

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
        variables
    end
    
    methods
        function obj = Datasource(props)
          % DATASOURCE - Construct a Datasource object from a struct
          %
          % Input arguments:
          % props - struct with optional fields used to populate properties
          %
          % This constructor copies known fields from props into the object.
            arguments
                props struct
            end
            
            % Set fields from input struct
            if isfield(props, 'coordinates')
                obj.coordinates = props.coordinates;
            end
            if isfield(props, 'created')
                obj.created = props.created;
            end
            if isfield(props, 'schema')
                obj.dataschema = props.schema;
            end
            if isfield(props, 'description')
                obj.description = props.description;
            end            
            if isfield(props, 'details')
                obj.details = props.details;
            end
            if isfield(props, 'driver')
                obj.driver = props.driver;
            end
            if isfield(props, 'args')
                obj.driver_args = props.args;
            end
            if isfield(props, 'expires')
                obj.expires = props.expires;
            end
            if isfield(props, 'geom')
                obj.geom = props.geom;
            end
            if isfield(props, 'id')
                obj.id = props.id;
            end
            if isfield(props, 'info')
                obj.info = props.info;
            end
            if isfield(props, 'labels')
                obj.labels = props.labels;
            end
            if isfield(props, 'modified')
                obj.modified = props.modified;
            end
            if isfield(props, 'name')
                obj.name = props.name;
            end
            if isfield(props, 'parameters')
                obj.parameters = props.parameters;
            end
            if isfield(props, 'parchive')
                obj.parchive = props.parchive;
            end
            if isfield(props, 'pforecast')
                obj.pforecast = props.pforecast;
            end
            if isfield(props, 'tags')
                obj.tags = props.tags;
            end
            if isfield(props, 'tend')
                obj.tend = props.tend;
            end
            if isfield(props, 'tstart')
                obj.tstart = props.tstart;
            end

            % Assign Properties 
            obj.attributes = props.metadata;

            obj.bounds = [min(props.geom.coordinates(:,:,1)), ...
                min(props.geom.coordinates(:,:,2)), ...
                max(props.geom.coordinates(:,:,1)), ...
                max(props.geom.coordinates(:,:,2))];


            obj.geometry = NaN; % TODO: Implement GeoJSON display of bounds
            obj.variables = props.schema.data_vars;


        end
        
        function str = char(obj)
          % CHAR - Create a human-readable summary of the datasource object
            str = sprintf('Datasource: %s [%s]', obj.name, obj.id);
            % if ~isempty(obj.description)
            %     str = sprintf('%s\nDescription: %s', str, obj.description);
            % end
            % Display extent and timerange of datasource
            bound = num2str(obj.bounds);
            str = sprintf("%s\nExtent: %s",str , bound);
            
            timerange = strcat(obj.tstart," to ", obj.tend);
            str = sprintf("%s\nTimerange: %s",str ,timerange); % TODO: Fix format.
            
            attribute = string(length(fieldnames(obj.attributes)));
            str = sprintf("%s\nAttributes: %s",str ,attribute);

            if ~isempty(obj.variables)
              % Format variables differently for cell arrays vs. other types
                vars = string(length(fieldnames(obj.variables)));
                str = sprintf('%s\nVariables: %s', str, vars);
            end
            
        end
        
        function disp(obj)
          % DISP - Print the char representation with a trailing newline
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